const float EPS = 1e-9;
const vec2 TL = vec2(-1.0, 1.0), TR = vec2(1.0, 1.0), BR = vec2(1.0, -1.0), BL = vec2(-1.0, -1.0);
const float TRAIL_MIN_DISTANCE2 = 0.01;
const float GLOW_GREY_DEV2 = 0.03;
const vec4 GLOW_COLOR_CURRENT = vec4(0.2, 0.4, 1.0, 1.0), GLOW_COLOR_PREVIOUS = vec4(0.4, 0.1, 1.0, 1.0);
const float GLOW_COLOR_OFFSET_BRIGHTNESS = 0.5;
const float GLOW_MIN_TRAVEL = 1.5;

float sq(float x) { return x * x; }
vec2 rectCenter(vec2 pos, vec2 size) { return pos + size * vec2(0.5, -0.5); }
bool insideRect(vec2 p, vec2 c, vec2 h) { return all(lessThanEqual(abs(p - c), h)); }

float rectSDF(vec2 p, vec2 c, vec2 h) { vec2 d = abs(p - c) - h; return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0); }

float sdSeg2(vec2 p, vec2 a) { vec2 c = a * clamp(dot(p, a) / (dot(a, a) + EPS), 0.0, 1.0) - p; return dot(c, c); }

float sdTriangle(vec2 p, vec2 a, vec2 b, vec2 c) {
    a -= p;
    b -= p;
    c -= p;
    vec3 t = cross(vec3(a.x, b.x, c.x), vec3(a.y, b.y, c.y));
    vec2 m = vec2(min(t.x, min(t.y, t.z)), max(t.x, max(t.y, t.z)));
    float s = -1.0 + 2.0 * step(m.x, 0.0) * step(0.0, m.y);
    return s * sqrt(min(sdSeg2(a, a - b), min(sdSeg2(b, b - c), sdSeg2(c, c - a))));
}

float sdTrail(vec2 p, vec2 currPos, vec2 currSize, vec2 prevPos, vec2 prevSize, float t) {
    vec2 currCenter = rectCenter(currPos, currSize);
    vec2 prevCenter = rectCenter(prevPos, prevSize);
    vec2 move = currCenter - prevCenter;

    bool nearbyPrev = dot(move, move) < TRAIL_MIN_DISTANCE2;
    bool insidePrev = insideRect(currCenter, prevCenter, prevSize * 0.5);

    float rectDist = max(rectSDF(p, currCenter, currSize * 0.5), 0.0);
    if (nearbyPrev || insidePrev) return rectDist;

    vec2 h = currSize * 0.5;
    vec2 corners[4] = vec2[4](currCenter + h * TL, currCenter + h * TR, currCenter + h * BR, currCenter + h * BL);
    vec2 triB = corners[0], triC = corners[0];
    float minRel = 1e9, maxRel = -minRel;
    for (int i = 0; i < 4; ++i) {
        vec2 delta = corners[i] - prevCenter;
        float rel = (move.x * delta.y - move.y * delta.x) / max(dot(move, delta), EPS);
        if (rel < minRel) { minRel = rel; triB = corners[i]; }
        if (rel > maxRel) { maxRel = rel; triC = corners[i]; }
    }

    float triDist = max(sdTriangle(p, prevCenter, triB, triC), 0.0);
    return min(rectDist, mix(triDist, rectDist, t));
}

vec4 colorOverride(vec4 baseColor, vec4 overrideColor) { vec3 dev = baseColor.rgb - vec3(dot(baseColor.rgb, vec3(1.0 / 3.0))); return dot(dev, dev) < GLOW_GREY_DEV2 ? overrideColor : baseColor; }

vec3 sRGBToLinear(vec3 c) { return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c)); }

vec2 px2n(vec2 v, float isPos) { return (v * 2.0 - iResolution.xy * isPos) / iResolution.y; }

float px2n(float v) { return v * 2.0 / iResolution.y; }
vec4 cursor2n(vec4 c) { return vec4(px2n(c.xy, 1.0), px2n(c.zw, 0.0)); }
float easeOutCirc(float x) { return sqrt(x * (2.0 - x)); }

float segSDF(vec2 p, vec2 a, vec2 b, inout float s, float d) {
    vec2 e = b - a, w = p - a;
    vec2 proj = a + e * clamp(dot(w, e) / (dot(e, e) + EPS), 0.0, 1.0);
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

float cornerDur(float dv, float lead, float side, float trail) { return dv >= 0.5 ? lead : dv >= -0.5 ? side : trail; }
float cornerProg(vec2 corner, vec2 s, float bias, float useBias, float t, float lead, float side, float trail) { return easeOutCirc(clamp(t / cornerDur(mix(dot(corner, s), bias, useBias), lead, side, trail), 0.0, 1.0)); }

const float T_DUR = 0.15;
const float T_SIZE = 0.8;
const float T_BLUR = 1.0;
const float T_THKX = 0.9;
const float T_FADE = 5.0;

const vec4 RIPPLE_COLOR = vec4(0.35, 0.36, 0.44, 0.8);
const float R_RAD = 0.5;
const float R_HALF_THK = 0.25;
const float R_TRIG = 0.5;
const float R_BLUR = 3.5;
const float R_START = 0.01;

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 base = texture(iChannel0, fragCoord / iResolution.xy);
    fragColor = base;
    float t = iTime - iTimeCursorChange;
    if (iFocus != 0 && t > T_DUR) return;

    vec4 cc = cursor2n(iCurrentCursor);
    vec2 ctrCC = rectCenter(cc.xy, cc.zw);

    if (iFocus == 0) {
        if (insideRect(px2n(fragCoord, 1.0), ctrCC, cc.zw * 0.5)) {
            float sy = clamp(fragCoord.y - iCurrentCursor.w, 0.0, iResolution.y - 1.0);
            fragColor = texture(iChannel0, vec2(fragCoord.x, sy) / iResolution.xy);
        }
        return;
    }

    {
        vec2 invRes = 1.0 / iResolution.xy;
        vec2 uv = fragCoord * invRes;
        vec2 currPos = iCurrentCursor.xy * invRes, currSize = iCurrentCursor.zw * invRes;
        vec2 prevPos = iPreviousCursor.xy * invRes, prevSize = iPreviousCursor.zw * invRes;
        vec2 currCenter = rectCenter(currPos, currSize);
        vec2 prevCenter = rectCenter(prevPos, prevSize);
        vec2 deltaCenter = currCenter - prevCenter;
        float dCenter2 = dot(deltaCenter, deltaCenter);
        float glowMinTravel = currSize.y * GLOW_MIN_TRAVEL;

        // Skip glow for typing and single-cell movement.
        if (dCenter2 > sq(glowMinTravel)) {
            float dSeg = dot(uv - prevCenter, deltaCenter) / (dCenter2 + EPS);
            bool nearbyPrev = dCenter2 < TRAIL_MIN_DISTANCE2;

            float u = 1.0 - clamp(t, 0.0, 1.0), tShape = 1.0 - u * u * u;
            float tVisible = exp(-t * 50.0);

            float dTrail = sdTrail(uv, currPos, currSize, prevPos, prevSize, tShape);
            float dTip = nearbyPrev ? 0.0 : clamp(1.0 - abs(dSeg - 1.0), 0.0, 1.0);

            vec4 currColor = colorOverride(iCurrentCursorColor, GLOW_COLOR_CURRENT);
            vec4 prevColor = colorOverride(iPreviousCursorColor, GLOW_COLOR_PREVIOUS);
            vec4 glowColor = mix(fragColor, mix(prevColor, currColor, dTip) + GLOW_COLOR_OFFSET_BRIGHTNESS, sq(dTip) * dTip);
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

    vec2 vu = px2n(fragCoord, 1.0);
    vec4 cp = cursor2n(iPreviousCursor);
    vec2 ctrCP = rectCenter(cp.xy, cp.zw);
    vec2 move = ctrCC - ctrCP;
    float move2 = dot(move, move);

    if (move2 > sq(cc.w) && t < T_DUR - 0.001) {
        vec2 hl = cc.zw * 0.5 * vec2(T_THKX, 1.0);
        vec2 hlP = cp.zw * 0.5 * vec2(T_THKX, 1.0);

        float DL = T_DUR * (1.0 - T_SIZE), DT = T_DUR, DS = (DL + DT) * 0.5;
        vec2 s = sign(move);
        float mR = step(0.5, s.x), mL = step(0.5, -s.x);

        float prog_tl = cornerProg(TL, s, -s.x, mL, t, DL, DS, DT);
        float prog_tr = cornerProg(TR, s, s.x, mR, t, DL, DS, DT);
        float prog_br = cornerProg(BR, s, s.x, mR, t, DL, DS, DT);
        float prog_bl = cornerProg(BL, s, -s.x, mL, t, DL, DS, DT);

        vec2 v_tl = mix(ctrCP + hlP * TL, ctrCC + hl * TL, prog_tl);
        vec2 v_tr = mix(ctrCP + hlP * TR, ctrCC + hl * TR, prog_tr);
        vec2 v_br = mix(ctrCP + hlP * BR, ctrCC + hl * BR, prog_br);
        vec2 v_bl = mix(ctrCP + hlP * BL, ctrCC + hl * BL, prog_bl);

        float sdfT = quadSDF(vu, v_tl, v_tr, v_br, v_bl);

        float fade = pow(clamp(dot(vu - ctrCP, move) / (move2 + EPS), 0.0, 1.0), T_FADE);

        float alpha = 1.0 - smoothstep(0.0, max(px2n(T_BLUR), 1e-5), sdfT);

        vec4 trail = vec4(sRGBToLinear(iCurrentCursorColor.rgb), iCurrentCursorColor.a);
        trail.a *= fade;
        fragColor = mix(fragColor, vec4(trail.rgb, fragColor.a), trail.a * alpha);
        if (insideRect(vu, ctrCC, cc.zw * 0.5)) fragColor = base;
    }

    float rP = t / T_DUR + R_START;
    if (abs(cc.z - cp.z) >= max(cc.z, cp.z) * R_TRIG && rP >= 0.0 && rP < 1.0) {
        float ep = easeOutCirc(rP);
        float sdfR = abs(distance(vu, ctrCC) - ep * cc.w * R_RAD) - cc.w * R_HALF_THK;
        float aaPx = px2n(R_BLUR);
        float ring = (1.0 - smoothstep(-aaPx, aaPx, sdfR)) * sq(1.0 - rP);
        fragColor = mix(fragColor, RIPPLE_COLOR, ring * RIPPLE_COLOR.a);
    }
}
