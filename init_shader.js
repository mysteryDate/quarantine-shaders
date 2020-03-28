let gl, glProgram;

function init(shadercode) {
  const vertexShader = gl.createShader(gl.VERTEX_SHADER);
  gl.shaderSource(vertexShader, `
    attribute vec2 pos;
    varying vec2 v_uv;
    void main() {
      v_uv = pos;
      gl_Position = vec4(pos, 0, 1);
    }`);
  gl.compileShader(vertexShader);
  gl.attachShader(glProgram, vertexShader);

  const fragmentShader = gl.createShader(gl.FRAGMENT_SHADER);
  gl.shaderSource(fragmentShader, shadercode);
  gl.compileShader(fragmentShader);
  if (!gl.getShaderParameter(fragmentShader, gl.COMPILE_STATUS)) {
    console.error(gl.getShaderInfoLog(fragmentShader));
  }

  gl.attachShader(glProgram, fragmentShader);
  gl.linkProgram(glProgram);
  if (!gl.getProgramParameter(glProgram, gl.LINK_STATUS)) {
    console.error(gl.getProgramInfoLog(glProgram));
  }

  gl.useProgram(glProgram);

  const bf = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, bf);
  gl.bufferData(gl.ARRAY_BUFFER, new Int8Array([-3, 1, 1, -3, 1, 1]),
    gl.STATIC_DRAW);

  gl.enableVertexAttribArray(0);
  gl.vertexAttribPointer(0, 2, gl.BYTE, 0, 0, 0);

  gl.uniform2f(gl.getUniformLocation(glProgram, "u_resolution"), canvas.width,
    canvas.height);
  gl.uniform2f(gl.getUniformLocation(glProgram, "u_mouse"), 0, 0);
  const texture = loadTexture(gl, 'textures/cait.jpg');
  gl.drawArrays(6, 0, 3);
}

function update() {
  gl.uniform1f(gl.getUniformLocation(glProgram, "u_time"),
    performance.now() / 1000);
  gl.drawArrays(6, 0, 3);
  requestAnimationFrame(update);
}

function createShaderCanvas(canvas, path) {
  gl = canvas.getContext("webgl");
  glProgram = gl.createProgram();

  canvas.onmousemove = function(e) {
    const x = (e.clientX - canvas.offsetLeft) / canvas.clientWidth;
    const y = 1.0 - (e.clientY - canvas.offsetTop) / canvas.clientHeight;
    gl.uniform2f(gl.getUniformLocation(glProgram, "u_mouse"), x, y);
  }

  function handleOrientation(e) {
    const x = e.gamma;
    const y = e.beta;
    gl.uniform2f(gl.getUniformLocation(glProgram, "u_mouse"), x, y);
  }

  fetch(path).then(response => response.text())
    .then((data) => {
      init(data);
      update();
    });
};

//
// Initialize a texture and load an image.
// When the image finished loading copy it into the texture.
//
function loadTexture(gl, url) {
  const texture = gl.createTexture();
  gl.bindTexture(gl.TEXTURE_2D, texture);

  // Because images have to be download over the internet
  // they might take a moment until they are ready.
  // Until then put a single pixel in the texture so we can
  // use it immediately. When the image has finished downloading
  // we'll update the texture with the contents of the image.
  const level = 0;
  const internalFormat = gl.RGBA;
  const width = 1;
  const height = 1;
  const border = 0;
  const srcFormat = gl.RGBA;
  const srcType = gl.UNSIGNED_BYTE;
  const pixel = new Uint8Array([0, 0, 255, 255]);  // opaque blue
  gl.texImage2D(gl.TEXTURE_2D, level, internalFormat,
                width, height, border, srcFormat, srcType,
                pixel);

  const image = new Image();
  image.onload = function() {
    gl.bindTexture(gl.TEXTURE_2D, texture);
    gl.texImage2D(gl.TEXTURE_2D, level, internalFormat,
                  srcFormat, srcType, image);

    // WebGL1 has different requirements for power of 2 images
    // vs non power of 2 images so check if the image is a
    // power of 2 in both dimensions.
    if (isPowerOf2(image.width) && isPowerOf2(image.height)) {
       // Yes, it's a power of 2. Generate mips.
       gl.generateMipmap(gl.TEXTURE_2D);
    } else {
       // No, it's not a power of 2. Turn off mips and set
       // wrapping to clamp to edge
       gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
       gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
       gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    }
  };
  image.src = url;

  return texture;
}

function isPowerOf2(value) {
  return (value & (value - 1)) == 0;
}