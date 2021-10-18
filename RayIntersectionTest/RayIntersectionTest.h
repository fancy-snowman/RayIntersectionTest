#pragma once

#include <iostream>
#include <Windows.h>
#include <assert.h>

#include <d3d11.h>
#include <dxgi.h>
#include <d3dcompiler.h>
#pragma comment(lib, "d3d11")
#pragma comment(lib, "dxgi")
#pragma comment(lib, "d3dcompiler")

#define ASSERT_HR(hr) assert(SUCCEEDED(hr))