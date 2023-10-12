uniform sampler2D backbuffer; // 前のフレームの内容が保存されたテクスチャ

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // 現在のピクセルの位置を取得
    vec2 uv = gl_FragCoord.xy / iResolution.xy;

    // バックバッファからの色を取得
    vec4 previousColor = texture2D(backbuffer, uv);

    // 新しい色を計算 (この例では前のフレームの色に少し赤を足す)
    vec4 newColor = previousColor + vec4(0.1, 0.0, 0.0, 0.0);

    fragColor = newColor;
}