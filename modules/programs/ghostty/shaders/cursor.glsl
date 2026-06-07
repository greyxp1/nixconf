// ─────────────────────────────────────────────────────────────────────────────
//  CRT CONFIGURATION
// ─────────────────────────────────────────────────────────────────────────────
const float EPS = 1e-9;
const float TRAIL_MIN_DISTANCE = 0.1;
const float GLOW_COLOR_OVERRIDE_THRESHOLD = 0.1;
const vec3 GLOW_COLOR_OVERRIDE_CURRENT = vec3(0.2, 0.4, 1.0);
const vec3 GLOW_COLOR_OVERRIDE_PREVIOUS = vec3(0.4, 0.1, 1.0);
const float GLOW_COLOR_OFFSET_BRIGHTNESS = 0.5;
const float TIME_DURATION_FACTOR = 1.0;
const float GLOW_MIN_TRAVEL = 1.5; // min travel in cursor-heights to enable glow (suppresses typing / single-char moves)

// ─────────────────────────────────────────────────────────────────────────────
//  UTILITIES
// ─────────────────────────────────────────────────────────────────────────────

float min_(float a, float b, float c) {
    return min(a, min(b, c));
}
float max_(float a, float b, float c) {
    return max(a, max(b, c));
}

// Axis-aligned rect SDF — single implementation shared by both effects.
// p: sample point | c: centre | h: half-extents
float rectSDF(vec2 p, vec2 c, vec2 h) {
    vec2 d = abs(p - c) - h;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}
// CRT-convention wrapper (top-left origin, full size) — keeps sdTrail unchanged.
float sdRectangle(vec2 p, vec2 tl, vec2 sz) {
    return rectSDF(p, tl + sz * vec2(0.5, -0.5), sz * 0.5);
}

float sdSeg(vec2 p, vec2 a) {
    vec2 c = a * clamp(dot(p, a) / (dot(a, a) + EPS), 0., 1.) - p;
    return sqrt(dot(c, c));
}

float sdTriangle(vec2 p, vec2 a, vec2 b, vec2 c) {
    a -= p;
    b -= p;
    c -= p;
    vec3 t = cross(vec3(a.x, b.x, c.x), vec3(a.y, b.y, c.y));
    vec2 m = vec2(min_(t.x, t.y, t.z), max_(t.x, t.y, t.z));
    float s = -1. + 2. * step(m.x, 0.) * step(0., m.y);
    return s * min_(sdSeg(a, a - b), sdSeg(b, b - c), sdSeg(c, c - a));
}

float sdTrail(vec2 p, vec2 currPos, vec2 currSize, vec2 prevPos, vec2 prevSize, float t) {
    vec2 currWidth = vec2(currSize.x, 0.0), currHeight = vec2(0.0, -currSize.y);
    vec2 currTopLeft = currPos;
    vec2 currTopRight = currTopLeft + currWidth;
    vec2 currBottomLeft = currTopLeft + currHeight;
    vec2 currBottomRight = currBottomLeft + currWidth;
    vec2 currCenter = (currTopLeft + currBottomRight) * 0.5;

    vec2 prevWidth = vec2(prevSize.x, 0.0), prevHeight = vec2(0.0, -prevSize.y);
    vec2 prevTopLeft = prevPos;
    vec2 prevTopRight = prevTopLeft + prevWidth;
    vec2 prevBottomLeft = prevTopLeft + prevHeight;
    vec2 prevBottomRight = prevBottomLeft + prevWidth;
    vec2 prevCenter = (prevTopLeft + prevBottomRight) * 0.5;

    bool nearbyPrev = distance(currCenter, prevCenter) < TRAIL_MIN_DISTANCE;
    bool insidePrev = (
        currCenter.x >= prevTopLeft.x && currCenter.x <= prevTopRight.x &&
            currCenter.y <= prevTopLeft.y && currCenter.y >= prevBottomLeft.y
        );

    float rectDist = max(sdRectangle(p, currTopLeft, currSize), 0.0);
    if (nearbyPrev || insidePrev) return rectDist;

    vec2[4] corners = {
            currTopLeft,
            currTopRight,
            currBottomRight,
            currBottomLeft
        };
    vec2 triB = corners[0], triC = corners[0], dir = normalize(currCenter - prevCenter);
    float minRel = 1 / EPS, maxRel = -minRel;
    for (int i = 0; i < 4; ++i) {
        vec2 delta = corners[i] - prevCenter;
        float rel = atan(dir.x * delta.y - dir.y * delta.x, dot(dir, delta));
        if (rel < minRel) minRel = rel, triB = corners[i];
        if (rel > maxRel) maxRel = rel, triC = corners[i];
    }

    float triDist = max(sdTriangle(p, prevCenter, triB, triC), 0.0);
    return min(rectDist, mix(triDist, rectDist, t));
}

// Returns override colour when RGB channels are near-grey (low std-dev), else base.
vec4 colorOverride(vec4 baseColor, vec4 overrideColor) {
    vec3 dev = baseColor.rgb - vec3(dot(baseColor.rgb, vec3(1.0 / 3.0)));
    return sqrt(dot(dev, dev) / 3.0) < GLOW_COLOR_OVERRIDE_THRESHOLD ? overrideColor : baseColor;
}

vec3 sRGBToLinear(vec3 c) {
    return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

// Pixels → Y-normalised space (Y ∈ [−1,1]).  isPos=1 for positions, 0 for sizes.
vec2 px2n(vec2 v, float isPos) {
    return (v * 2.0 - iResolution.xy * isPos) / iResolution.y;
}

float easeOutCirc(float x) {
    return sqrt(1.0 - pow(x - 1.0, 2.0));
}
float easeOutPulse(float t) {
    return t * (2.0 - t);
}

// Signed segment contribution to convex-quad SDF (Inigo Quilez).
float segSDF(vec2 p, vec2 a, vec2 b, inout float s, float d) {
    vec2 e = b - a, w = p - a;
    vec2 proj = a + e * clamp(dot(w, e) / dot(e, e), 0.0, 1.0);
    d = min(d, dot(p - proj, p - proj));
    float c0 = step(0.0, p.y - a.y), c1 = 1.0 - step(0.0, p.y - b.y);
    float c2 = 1.0 - step(0.0, e.x * w.y - e.y * w.x);
    s *= mix(1.0, -1.0, step(0.5, c0 * c1 * c2 + (1.0 - c0) * (1.0 - c1) * (1.0 - c2)));
    return d;
}

float quadSDF(vec2 p, vec2 v0, vec2 v1, vec2 v2, vec2 v3) {
    float s = 1.0, d = dot(p - v0, p - v0);
    d = segSDF(p, v0, v1, s, d);
    d = segSDF(p, v1, v2, s, d);
    d = segSDF(p, v2, v3, s, d);
    d = segSDF(p, v3, v0, s, d);
    return s * sqrt(d);
}

// Per-corner animation duration based on alignment with move direction.
float cornerDur(float dv, float lead, float side, float trail) {
    float isL = step(0.5, dv), isS = step(-0.5, dv) * (1.0 - isL);
    return mix(mix(trail, side, isS), lead, isL);
}

// ─────────────────────────────────────────────────────────────────────────────
//  WARP + RIPPLE CONFIGURATION
// ─────────────────────────────────────────────────────────────────────────────

vec4 TRAIL_COLOR = vec4(sRGBToLinear(iCurrentCursorColor.rgb), iCurrentCursorColor.a);
const float T_DUR = 0.15; // duration (s)
const float T_SIZE = 0.8; // smear: 0 = corners sync, 1 = max smear
const float T_DIST = 1.0; // min travel to show trail (× cursor height)
const float T_BLUR = 1.0; // AA blur (px)
const float T_THK = 1.0; // vertical thickness (1 = full cursor height)
const float T_THKX = 0.9; // horizontal thickness
const float T_FADE = 5.0; // tail-to-head fade exponent

vec4 RIPPLE_COLOR = vec4(0.35, 0.36, 0.44, 0.8);
const float R_DUR = 0.15;
const float R_RAD = 0.5; // max radius (× cursor height; 0.5 → diam = 1 line)
const float R_THK = 0.5; // ring width  (× cursor height)
const float R_TRIG = 0.5; // cursor-width Δ fraction that fires ripple
const float R_BLUR = 3.5; // AA blur (px)
const float R_START = 0.01; // initial progress offset

// ─────────────────────────────────────────────────────────────────────────────
//  MAIN
// ─────────────────────────────────────────────────────────────────────────────

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 base = texture(iChannel0, fragCoord / iResolution.xy);
    fragColor = base;

    // Unfocused: hide cursor by sampling the line below, then exit.
    //if (iFocus == 0) {
    //    vec2 vu0  = px2n(fragCoord, 1.0);
    //    vec4 cc0  = vec4(px2n(iCurrentCursor.xy, 1.0), px2n(iCurrentCursor.zw, 0.0));
    //    vec2 ctr0 = cc0.xy - cc0.zw * vec2(-0.5, 0.5);
    //    if (rectSDF(vu0, ctr0, cc0.zw * 0.5) <= 0.0) {
    //        float sy  = clamp(fragCoord.y - iCurrentCursor.w, 0.0, iResolution.y - 1.0);
    //        fragColor = texture(iChannel0, vec2(fragCoord.x, sy) / iResolution.xy);
    //    }
    //    return;
    //}

    float t = iTime - iTimeCursorChange;

    // ── CRT glow trail ───────────────────────────────────────────────────────
    {
        vec2 invRes = 1.0 / iResolution.xy;
        vec2 uv = fragCoord * invRes;
        vec2 currPos = iCurrentCursor.xy * invRes, currSize = iCurrentCursor.zw * invRes;
        vec2 prevPos = iPreviousCursor.xy * invRes, prevSize = iPreviousCursor.zw * invRes;
        vec2 currCenter = currPos + currSize * vec2(0.5, -0.5);
        vec2 prevCenter = prevPos + prevSize * vec2(0.5, -0.5);

        float dCenter = distance(currCenter, prevCenter);

        // Skip glow for small moves (typing or single-character navigation).
        // GLOW_MIN_TRAVEL is in units of cursor height, so 1.5 means the cursor
        // must travel more than 1.5x its own height before the glow fires.
        // Typical values: 1 char horizontal ~0.5 heights, 1 line vertical ~1 height.
        if (dCenter > currSize.y * GLOW_MIN_TRAVEL) {
            float dSeg = dot(uv - prevCenter, currCenter - prevCenter) * pow(dCenter + EPS, -2);
            bool nearbyPrev = dCenter < TRAIL_MIN_DISTANCE;

            float tShape = 1.0 - pow(1.0 - clamp(t / TIME_DURATION_FACTOR, 0.0, 1.0), 3);
            float tVisible = exp(-t / TIME_DURATION_FACTOR * 50.0);

            float dTrail = sdTrail(uv, currPos, currSize, prevPos, prevSize, tShape);
            float dTip = nearbyPrev ? 0.0 : clamp(1.0 - abs(dSeg - 1.0), 0.0, 1.0);

            vec4 currColor = colorOverride(iCurrentCursorColor, vec4(GLOW_COLOR_OVERRIDE_CURRENT, 1.0));
            vec4 prevColor = colorOverride(iPreviousCursorColor, vec4(GLOW_COLOR_OVERRIDE_PREVIOUS, 1.0));
            vec4 glowColor = mix(fragColor, mix(prevColor, currColor, dTip) + GLOW_COLOR_OFFSET_BRIGHTNESS, pow(dTip, 3));
            glowColor = mix(glowColor, fragColor, pow(smoothstep(0.0, 0.3, dTrail), 0.1));

            vec4 trailColor = mix(vec4(1.0), glowColor, pow(smoothstep(0.0, 0.01, dTrail), 0.2));
            vec4 trail = mix(trailColor, fragColor, pow(smoothstep(0.0, nearbyPrev ? 0.01 : 0.1, dTrail), 0.2));
            if (!nearbyPrev) {
                trail = mix(trailColor, trail, pow(smoothstep(0.0, 6.0, dTip), 0.05));
                trail = mix(trailColor, trail, pow(smoothstep(0.0, 8.0, dTip), 0.005));
            }

            fragColor = mix(fragColor, trail, tVisible);
        }
    }

    // ── Shared warp/ripple setup (Y-normalised space) ─────────────────────────
    vec2 vu = px2n(fragCoord, 1.0);
    vec4 cc = vec4(px2n(iCurrentCursor.xy, 1.0), px2n(iCurrentCursor.zw, 0.0));
    vec4 cp = vec4(px2n(iPreviousCursor.xy, 1.0), px2n(iPreviousCursor.zw, 0.0));
    vec2 ctrCC = cc.xy - cc.zw * vec2(-0.5, 0.5);
    vec2 ctrCP = cp.xy - cp.zw * vec2(-0.5, 0.5);

    // ── Warp trail ───────────────────────────────────────────────────────────
    if (distance(ctrCC, ctrCP) > cc.w * T_DIST && t < T_DUR - 0.001) {
        vec2 hl = cc.zw * 0.5 * vec2(T_THKX, T_THK);
        vec2 hlP = cp.zw * 0.5 * vec2(T_THKX, T_THK);

        vec2 cc_tl = ctrCC + vec2(-hl.x, hl.y), cc_tr = ctrCC + vec2(hl.x, hl.y);
        vec2 cc_br = ctrCC + vec2(hl.x, -hl.y), cc_bl = ctrCC + vec2(-hl.x, -hl.y);
        vec2 cp_tl = ctrCP + vec2(-hlP.x, hlP.y), cp_tr = ctrCP + vec2(hlP.x, hlP.y);
        vec2 cp_br = ctrCP + vec2(hlP.x, -hlP.y), cp_bl = ctrCP + vec2(-hlP.x, -hlP.y);

        float DL = T_DUR * (1.0 - T_SIZE), DT = T_DUR, DS = (DL + DT) * 0.5;
        vec2 s = sign(ctrCC - ctrCP);
        float mR = step(0.5, s.x), mL = step(0.5, -s.x);

        float prog_tl = easeOutCirc(clamp(t / cornerDur(mix(dot(vec2(-1., 1.), s), -s.x, mL), DL, DS, DT), 0., 1.));
        float prog_tr = easeOutCirc(clamp(t / cornerDur(mix(dot(vec2(1., 1.), s), s.x, mR), DL, DS, DT), 0., 1.));
        float prog_br = easeOutCirc(clamp(t / cornerDur(mix(dot(vec2(1., -1.), s), s.x, mR), DL, DS, DT), 0., 1.));
        float prog_bl = easeOutCirc(clamp(t / cornerDur(mix(dot(vec2(-1., -1.), s), -s.x, mL), DL, DS, DT), 0., 1.));

        vec2 v_tl = mix(cp_tl, cc_tl, prog_tl), v_tr = mix(cp_tr, cc_tr, prog_tr);
        vec2 v_br = mix(cp_br, cc_br, prog_br), v_bl = mix(cp_bl, cc_bl, prog_bl);

        float sdfT = quadSDF(vu, v_tl, v_tr, v_br, v_bl);

        vec2 mv = ctrCC - ctrCP;
        float fade = pow(clamp(dot(vu - ctrCP, mv) / (dot(mv, mv) + 1e-6), 0.0, 1.0), T_FADE);

        float blur = mix(0.0, T_BLUR, T_BLUR < 2.5 ? abs(s.x) * abs(s.y) : 1.0);
        float alpha = 1.0 - smoothstep(0.0, max(px2n(vec2(blur), 0.0).x, 1e-5), sdfT);

        vec4 trail = TRAIL_COLOR;
        trail.a *= fade;
        fragColor = mix(fragColor, vec4(trail.rgb, fragColor.a), trail.a * alpha);
        fragColor = mix(fragColor, base, step(rectSDF(vu, ctrCC, cc.zw * 0.5), 0.0));
    }

    // ── Ripple ───────────────────────────────────────────────────────────────
    float rP = t / R_DUR + R_START;
    if (abs(cc.z - cp.z) >= max(cc.z, cp.z) * R_TRIG && rP < 1.0) {
        float ep = easeOutCirc(rP);
        float sdfR = abs(distance(vu, ctrCC) - ep * cc.w * R_RAD) - cc.w * R_THK * 0.5;
        float aaPx = px2n(vec2(R_BLUR), 0.0).x;
        float ring = (1.0 - smoothstep(-aaPx, aaPx, sdfR)) * (1.0 - easeOutPulse(rP));
        fragColor = mix(fragColor, RIPPLE_COLOR, ring * RIPPLE_COLOR.a);
    }
}
