RWTexture2D<float4> backbuffer : register(u0);

float magnitude(float2 v)
{
	return sqrt(v.x * v.x + v.y * v.y);
}

float distance(float2 v, float2 u)
{
	return magnitude(u - v);
}

float2 mandelbrot_func(float2 z, float2 c)
{
	/*
		(a + bi) * (a + bi)
		a*a + 2*a*bi + b*b*i*i
		a*a + 2*a*bi - b*b
		(a*a - b*b) + (2*a*b)i
	*/

	return float2(z.x * z.x - z.y * z.y, 2 * z.x * z.y) + c;
}

int mandelbrot(float2 position, int maxIterations)
{
	float2 z = 0;
	int iterations = 0;

	for (int i = 0; i < maxIterations; i++)
	{
		iterations++;

		z = mandelbrot_func(z, position);

		if (magnitude(z) > 2.0f)
		{
			return iterations;
		}
	}

	return iterations;
}

struct Input
{
	uint3 DTid : SV_DispatchThreadID;
};

[numthreads(1, 1, 1)]
void main(Input input)
{
	// TODO: Put into a buffer instead
	const int SCREEN_WIDTH = 800;
	const int SCREEN_HEIGHT = 600;

	float3 color = float3(0.2, 0.1f, 0.2f);
	//float2 position = input.DTid.xy - float2((float)SCREEN_WIDTH, (float)SCREEN_HEIGHT) / 2.f;
	float2 position = ((input.DTid.xy / float2((float)SCREEN_WIDTH, (float)SCREEN_HEIGHT)) * 2.0f) - float2(1.0f, 1.0f);

	position /= 20.f;
	position -= 0.57f;

	//if (distance(position, float2(0.0f, 0.0f)) < 100.f)
	//{
	//	color = float4(0.6, 0.4f, 0.6f, 1.0f);
	//}

	float factor = (float)mandelbrot(position, 120) / 120.f;
	color = float3(0.1f, 0.1f, 0.1f) + float3(0.2f, 0.5f, 0.6f) * factor;

	backbuffer[input.DTid.xy] = float4(color, 1.0f);
}