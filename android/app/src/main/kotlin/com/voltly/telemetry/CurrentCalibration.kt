package com.voltly.telemetry

/**
 * Learns how this particular device reports battery current.
 *
 * Android documents BATTERY_PROPERTY_CURRENT_NOW/AVERAGE as microamperes with
 * a positive value meaning current flowing into the battery. In practice a
 * meaningful share of devices deviate:
 * - some vendor kernels report milliamperes instead of microamperes;
 * - some report the opposite sign (positive while discharging).
 *
 * Both deviations are inferred only from unambiguous observations and are
 * then remembered so later readings are normalized consistently:
 * - Unit: a magnitude above 20,000 can only be microamperes (20 A is not
 *   plausible), which locks microamperes. A non-zero magnitude below 10,000
 *   while the phone is unplugged and discharging with the app in the
 *   foreground (screen on, so the real draw is well above 10 mA) can only be
 *   milliamperes.
 * - Sign: while unplugged and discharging, real current must leave the
 *   battery. A positive raw value at that moment means the device inverts the
 *   documented convention.
 *
 * Until the sign has been learned from a discharging observation, a negative
 * reading while the device reports charging is provisionally treated as
 * inverted. That inference is not persisted because a heavily loaded phone on
 * a weak charger can legitimately discharge while plugged in.
 *
 * This class is pure and holds no Android references so it is JVM-testable.
 */
internal class CurrentCalibration(
    reportsMilliamps: Boolean = false,
    signInverted: Boolean = false,
    signLearned: Boolean = false,
) {
    var reportsMilliamps: Boolean = reportsMilliamps
        private set
    var signInverted: Boolean = signInverted
        private set
    var signLearned: Boolean = signLearned
        private set

    /**
     * Updates the learned calibration from one raw CURRENT_NOW observation.
     * Returns true when a persisted field changed.
     */
    fun observe(rawCurrentNow: Int?, pluggedRaw: Int?, statusName: String?): Boolean {
        if (rawCurrentNow == null) return false
        var changed = false
        val magnitude = kotlin.math.abs(rawCurrentNow.toLong())
        val unpluggedDischarging = pluggedRaw == 0 && statusName == "discharging"

        if (magnitude > MICROAMP_ONLY_THRESHOLD) {
            if (reportsMilliamps) {
                reportsMilliamps = false
                changed = true
            }
        } else if (unpluggedDischarging &&
            magnitude in 1 until MILLIAMP_EVIDENCE_THRESHOLD &&
            !reportsMilliamps
        ) {
            reportsMilliamps = true
            changed = true
        }

        if (unpluggedDischarging) {
            val microamps = toMicroamps(rawCurrentNow)
            if (kotlin.math.abs(microamps) >= MIN_SIGN_EVIDENCE_MICROAMPS) {
                val inverted = microamps > 0
                if (!signLearned || inverted != signInverted) {
                    signInverted = inverted
                    signLearned = true
                    changed = true
                }
            }
        }
        return changed
    }

    /**
     * Converts a raw current property to signed amperes using the learned
     * calibration. Returns null for implausible magnitudes.
     *
     * [statusName] enables the provisional, unpersisted sign inference used
     * before any discharging observation has been seen.
     */
    fun toAmperes(raw: Int, statusName: String? = null): Double? {
        val microamps = toMicroamps(raw)
        if (kotlin.math.abs(microamps) > MAX_PLAUSIBLE_MICROAMPS) return null
        val invert = if (signLearned) {
            signInverted
        } else {
            statusName == "charging" && microamps < -MIN_SIGN_EVIDENCE_MICROAMPS
        }
        val signed = if (invert) -microamps else microamps
        return signed / 1_000_000.0
    }

    private fun toMicroamps(raw: Int): Long =
        if (reportsMilliamps) raw.toLong() * 1_000L else raw.toLong()

    companion object {
        /** Above this raw magnitude a value can only be microamperes. */
        const val MICROAMP_ONLY_THRESHOLD = 20_000L

        /** Below this raw magnitude while discharging, the unit is mA. */
        const val MILLIAMP_EVIDENCE_THRESHOLD = 10_000L

        /** 5 mA: smaller readings are too close to zero to trust the sign. */
        const val MIN_SIGN_EVIDENCE_MICROAMPS = 5_000L

        const val MAX_PLAUSIBLE_MICROAMPS = 20_000_000L
    }
}
