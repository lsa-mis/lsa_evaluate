module.exports = {
  testEnvironment: 'jsdom',
  roots: ['spec/javascript'],
  moduleDirectories: ['node_modules', 'app/javascript'],
  setupFiles: ['<rootDir>/spec/javascript/setup.js'],
  transform: {
    '^.+\\.(js|jsx|ts|tsx)$': 'babel-jest',
  },
  moduleNameMapper: {
    '^@hotwired/stimulus': '<rootDir>/node_modules/@hotwired/stimulus',
    '^sortablejs': '<rootDir>/node_modules/sortablejs',
  },
  testPathIgnorePatterns: ['/node_modules/', '/vendor/'],
  collectCoverage: true,
  collectCoverageFrom: [
    'app/javascript/**/*.{js,jsx,ts,tsx}',
    '!app/javascript/channels/**',
    '!app/javascript/packs/**',
  ],
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov'],
}
