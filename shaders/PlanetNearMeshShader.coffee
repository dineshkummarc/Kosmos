
frag = """

precision mediump float;

varying vec3 vNormal;
varying vec2 vUV;
varying float camDist;

uniform float alpha;
uniform vec3 lightVec;
uniform sampler2D sampler;

uniform vec4 uvRect;

const float uvScalar = 4097.0 / 4096.0;
#define ONE_TEXEL (1.0/4096.0)

	//vec3 planetColor1 = vec3(0.2, 0.6, 0.3);
	//vec3 planetColor2 = vec3(0.4, 0.3, 0.1);

	//vec3 planetColor1 = vec3(1, 1, 1);
	//vec3 planetColor2 = vec3(0.5, 0.5, 0.5);

	vec3 planetColor1 = vec3(0.75, 0.3, 0.0);
	vec3 planetColor2 = vec3(0.5, 0.0, 0.0);


vec3 computeLighting(float globalDot, float diffuse, float ambient, vec3 color)
{
	float nightBlend = clamp(0.5 - globalDot * 4.0, 0.0, 1.0);
 	float nightLight = clamp(0.2 / sqrt(camDist) - 0.001, 0.0, 1.0);
 	float ambientNight = nightBlend * (ambient * ambient * 0.14 + 0.02) * nightLight;

 	float grayColor = (color.r + color.g + color.b) / 3.0;
 	vec3 nightColor = vec3(grayColor * 0.4, grayColor * 0.1, grayColor * 1.0);

 	return color * diffuse + nightColor * ambientNight;
}

vec3 computeColor(float height, float ambient)
{
	float selfShadowing = 1.01 - dot(planetColor1, vec3(1,1,1)/3.0);

	vec3 color = vec3(1,1,1);
	float edge = mix(1.0, ambient, selfShadowing);
	color *= mix(planetColor2, vec3(1,1,1) * edge, clamp(abs(height - 0.0) / 1.5, 0.0, 1.0));
	color *= mix(planetColor1, vec3(1,1,1) * edge, clamp(abs(height - 0.5) / 2.5, 0.0, 1.0));

	color *= height * 0.25 + 1.00;

	return color;
}

void main(void) {
	// extract terrain info
	vec4 tex = texture2D(sampler, vUV * uvScalar, -0.5);
	vec3 norm = normalize(tex.xyz * 2.0 - 1.0);

	// compute terrain shape features values
	float globalDot = dot(lightVec, vNormal);
	float diffuse = clamp(dot(lightVec, norm), 0.0, 1.0);
 	float ambient = clamp(1.0 - 2.0 * acos(dot(norm, normalize(vNormal))), 0.0, 1.0);
	float height = tex.a;

	// compute color based on terrain features
 	vec3 color = computeColor(height, ambient);

	gl_FragColor.xyz = computeLighting(globalDot, diffuse, ambient, color);

    gl_FragColor.w = 1.0; //alpha;
}

"""


vert = """

precision highp float;

attribute vec3 aUV;

uniform mat4 projMat;
uniform mat4 modelViewMat;
uniform mat3 cubeMat;

varying vec3 vNormal;
varying vec2 vUV;
varying float camDist;

uniform vec4 uvRect;
uniform sampler2D vertSampler;

const float uvScalar = 4097.0 / 4096.0;

void main(void) {
	vec2 uv = aUV.xy * uvRect.zw + uvRect.xy;

	vec3 aPos = vec3(uv * 2.0 - 1.0, 1.0);
	aPos = normalize(aPos * cubeMat);

	float height = texture2D(vertSampler, uv * uvScalar).a;
	aPos *= 0.99 + (height - (uvRect.z * 3.0) * aUV.z) * 0.01;

	vNormal = aPos;
	vUV = uv.xy;

	vec4 pos = vec4(aPos, 1.0);
	pos = modelViewMat * pos;
    gl_Position = projMat * pos;

    camDist = length(pos.xyz);
}

"""

xgl.addProgram("planetNearMesh", vert, frag)
