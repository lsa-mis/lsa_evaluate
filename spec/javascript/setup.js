// Set up DOM environment
require('@testing-library/jest-dom')

// Mock Bootstrap
global.bootstrap = {
  Modal: jest.fn().mockImplementation(() => ({
    show: jest.fn(),
    hide: jest.fn(),
    element: document.createElement('div')
  }))
}
