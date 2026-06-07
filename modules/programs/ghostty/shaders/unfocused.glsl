void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    fragColor = texture(iChannel0, uv);
    if (iFocus == 0) {
        float minX = iCurrentCursor.x;
        float maxX = iCurrentCursor.x + iCurrentCursor.z;
        float minY = iCurrentCursor.y - iCurrentCursor.w;
        float maxY = iCurrentCursor.y;
        if (fragCoord.x >= minX && fragCoord.x <= maxX &&
                fragCoord.y >= minY && fragCoord.y <= maxY) {
            float thickness = 2.0;
            bool isBorder = (fragCoord.x < minX + thickness || fragCoord.x > maxX - thickness ||
                    fragCoord.y < minY + thickness || fragCoord.y > maxY - thickness);
            if (isBorder) {
                float sampleX = (minX > 10.0) ? minX - 5.0 : maxX + 5.0;
                vec2 bgUv = vec2(sampleX, minY + (iCurrentCursor.w * 0.5)) / iResolution.xy;
                fragColor = texture(iChannel0, bgUv);
            }
        }
    }
}
