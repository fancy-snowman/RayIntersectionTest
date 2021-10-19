RWTexture2D<float4> backbuffer : register(u0);

struct Ray
{
	float3 origin;
	float3 direction;
};

struct Hit
{
	float t;
	float3 position;
	float3 normal;
	float3 color;
};

struct Sphere
{
	float3 position;
	float radius;
	float3 color;
};

struct OBB
{
	float3 position;
	float3 boxX;
	float3 boxY;
	float3 halfSize;
	float3 color;
};

Ray ConstructRay(float3 cameraPos, float3 direction, int2 threadID, int2 screenSize)
{
	float3 up = float3(0.f, 1.f, 0.f);
	float3 right = cross(up, direction);
	up = cross(direction, right);

	float2 halfSize = float2(screenSize.x, screenSize.y) / 2.f;
	float2 offset = float2(threadID) - halfSize;
	offset.y *= -1.f;

	Ray ray;
	ray.direction = direction;
	ray.origin = cameraPos + right * offset.x + up * offset.y;

	return ray;
}

bool SphereCollisionTest(Ray ray, Sphere sphere, out Hit hit)
{
	float b = dot(ray.direction, ray.origin - sphere.position);
	float c = dot(ray.origin - sphere.position, ray.origin - sphere.position) - sphere.radius * sphere.radius;
	float s = b * b - c;

	if (s < 0)
	{
		return false;
	}

	float t1 = -b - sqrt(s);
	float t2 = -b + sqrt(s);

	if (t1 > t2)
	{
		float temp = t1;
		t1 = t2;
		t2 = temp;
	}

	hit.t = t1;
	hit.position = ray.origin + ray.direction * hit.t;
	hit.normal = normalize(hit.position - sphere.position);
	hit.color = sphere.color;
	return true;
}

bool OBBCollisionTest(Ray ray, OBB obb, out Hit hit)
{
	float tMin = -999999.f;
	float tMax = 999999.f;
	float3 p = obb.position - ray.origin;
	
	float3 dir[] =
	{
		normalize(obb.boxX),
		normalize(obb.boxY),
		normalize(cross(obb.boxX, obb.boxY))
	};


	int iMin = -1;
	for (int i = 0; i < 3; i++)
	{
		float e = dot(dir[i], p);
		float f = dot(dir[i], ray.direction);

		if (abs(f) > 0.0001f)
		{
			float t1 = (e + obb.halfSize[i]) / f;
			float t2 = (e - obb.halfSize[i]) / f;

			if (t1 > t2)
			{
				float temp = t1;
				t1 = t2;
				t2 = temp;
			}

			if (t1 > tMin)
			{
				tMin = t1;
				iMin = i;
			}

			if (t2 < tMax)
			{
				tMax = t2;
			}

			if (tMin > tMax || tMax < 0.f)
			{
				return false;
			}
		}

		else if (-e - obb.halfSize[i] > 0 || -e + obb.halfSize[i] < 0.f)
		{
			return false;
		}
	}

	if (tMin > 0.f)
	{
		hit.t = tMin;
		hit.position = ray.origin + ray.direction * hit.t;

		float3 n1 = dir[iMin];
		float3 n2 = dir[iMin] * -1.f;
		hit.normal = (dot(n1, ray.direction) > dot(n2, ray.direction)) ? n2 : n1;
		hit.color = obb.color;

		return true;
	}
	
	// OBB behind ray origin
	//hit.t = tMax;
	//hit.position = ray.origin + ray.direction * hit.t;
	//hit.normal = dir[1];
	//return true;
	return false;
}

struct Input
{
	uint3 DTid : SV_DispatchThreadID;
};

[numthreads(1, 1, 1)]
void main(Input input)
{
	// TODO: Put into a buffer instead
	const int2 SCREEN_SIZE = int2(800, 600);
	const float3 BACKGROUND_COLOR = float3(0.2, 0.1f, 0.2f);

	float3 color = BACKGROUND_COLOR;

	Ray ray = ConstructRay(
		float3(0.f, 0.f, 0.f),
		float3(0.f, 0.f, 1.f),
		input.DTid.xy,
		SCREEN_SIZE
	);

	

	// ---

	Sphere sphere;
	sphere.position = float3(0.f, 0.f, 200.f);
	sphere.radius = 80.f;
	sphere.color = float3(0.8f, 0.5f, 0.2f);

	// ---

	OBB box;
	box.position = float3(0.f, 0.f, 200.f);
	box.boxX = normalize(float3(1.f, 0.f, -0.5f));
	box.boxY = normalize(float3(-0.8f, 0.8f, -0.2f));
	float3 tempZ = cross(box.boxX, box.boxY);
	box.boxY = normalize(cross(tempZ, box.boxX));
	box.halfSize = float3(100.f, 50.f, 50.f);
	box.color = float3(0.3f, 0.8f, 0.5f);

	// ---

	Hit hit;
	Hit closestHit;
	closestHit.t = 99999999.f;
	bool anyHit = false;

	if (OBBCollisionTest(ray, box, hit) && hit.t < closestHit.t)
	{
		closestHit = hit;
		anyHit = true;
	}

	if (SphereCollisionTest(ray, sphere, hit) && hit.t < closestHit.t)
	{
		closestHit = hit;
		anyHit = true;
	}	

	if (anyHit)
	{
		float3 lightDir = normalize(float3(1.f, -1.f, 1.f));
		float factor = saturate(dot(lightDir * -1.f, closestHit.normal));
		color = closestHit.color * factor;
	}

	// ---

	backbuffer[input.DTid.xy] = float4(color, 1.0f);
}