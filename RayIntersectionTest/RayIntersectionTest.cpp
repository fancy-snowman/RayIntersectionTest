#include "RayIntersectionTest.h"

int main()
{
	const int SCREEN_WIDTH = 800;
	const int SCREEN_HEIGHT = 600;
	HWND window;

	/*
		Initialize the window
	*/
	{
		auto procedure = [](HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam) -> LRESULT {
			switch (uMsg)
			{
			case WM_DESTROY: // Window x-button is pressed
				PostQuitMessage(0);
				return 0;
			}

			// Must return default if not handled
			return DefWindowProc(hwnd, uMsg, wParam, lParam);
		};

		const char WND_CLASS_NAME[] = "Ray tracer";
		WNDCLASS windowClass = { 0 };
		windowClass.lpfnWndProc = procedure;
		windowClass.hInstance = nullptr;
		windowClass.lpszClassName = WND_CLASS_NAME;
		RegisterClass(&windowClass);

		window = CreateWindowExA(
			NULL,
			WND_CLASS_NAME,
			"Ray Tracer",
			WS_OVERLAPPEDWINDOW,
			CW_USEDEFAULT,
			CW_USEDEFAULT,
			SCREEN_WIDTH,
			SCREEN_HEIGHT,
			NULL,
			NULL,
			NULL,
			NULL
		);
		assert(window);
		ShowWindow(window, SW_SHOW);
	}

	/*
		Initialize Direct 3D
	*/

	ID3D11Device* device = nullptr;
	ID3D11DeviceContext* context = nullptr;
	IDXGISwapChain* swapChain = nullptr;
	ID3D11UnorderedAccessView* backBufferView = nullptr;

	{
		DXGI_SWAP_CHAIN_DESC swapChainDesc = { 0 };
		swapChainDesc.BufferDesc.Width = SCREEN_WIDTH;
		swapChainDesc.BufferDesc.Height = SCREEN_HEIGHT;
		swapChainDesc.BufferDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
		swapChainDesc.SampleDesc.Count = 1;
		swapChainDesc.BufferUsage = DXGI_USAGE_UNORDERED_ACCESS;
		swapChainDesc.BufferCount = 1;
		swapChainDesc.OutputWindow = window;
		swapChainDesc.Windowed = true;
		swapChainDesc.SwapEffect = DXGI_SWAP_EFFECT_SEQUENTIAL;

		ASSERT_HR(D3D11CreateDeviceAndSwapChain(
			NULL,
			D3D_DRIVER_TYPE_HARDWARE,
			NULL,
			D3D11_CREATE_DEVICE_DEBUG,
			NULL,
			NULL,
			D3D11_SDK_VERSION,
			&swapChainDesc,
			&swapChain,
			&device,
			NULL,
			&context
		));

		ID3D11Texture2D* backBuffer = nullptr;
		swapChain->GetBuffer(0, IID_PPV_ARGS(&backBuffer));
		ASSERT_HR(device->CreateUnorderedAccessView(backBuffer, NULL, &backBufferView));
	}

	ID3D11ComputeShader* shader = nullptr;

	{
		ID3DBlob* shaderBlob = nullptr;
		ID3DBlob* errorBlob = nullptr;

		HRESULT hr = D3DCompileFromFile(L"../../../shader.hlsl", NULL, NULL, "main", "cs_5_0", NULL, NULL, &shaderBlob, &errorBlob);

		if (FAILED(hr))
		{
			OutputDebugStringA((char*)errorBlob->GetBufferPointer());
			delete errorBlob;
			ASSERT_HR(hr);
		}

		ASSERT_HR(device->CreateComputeShader(shaderBlob->GetBufferPointer(), shaderBlob->GetBufferSize(), NULL, &shader));
	}

	/*
		Run the main loop
	*/

	MSG msg;
	while (IsWindow(window))
	{
		while (PeekMessage(&msg, window, NULL, NULL, PM_REMOVE))
		{
			TranslateMessage(&msg);
			DispatchMessage(&msg);
		}

		// Bind the back buffer to the shader
		const UINT UAVInitialCounts = -1; // -1 indicates to keep the current offset, -MSDN
		context->CSSetUnorderedAccessViews(0, 1, &backBufferView, &UAVInitialCounts);

		// Execute the compute shader
		context->CSSetShader(shader, NULL, 0);
		context->Dispatch(SCREEN_WIDTH, SCREEN_HEIGHT, 1);

		// Present the window
		swapChain->Present(0, 0);
	}



	return 0;
}
