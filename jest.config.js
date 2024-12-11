module.exports = {
  testEnvironment: 'jsdom',
  roots: ['spec/javascript'],
  moduleDirectories: ['node_modules', 'app/javascript'],
  setupFilesAfterEnv: ['<rootDir>/spec/javascript/setup.js'],
  transform: {
    '^.+\\.(js|jsx|ts|tsx)$': ['babel-jest', { presets: ['@babel/preset-env'] }],
  },
  transformIgnorePatterns: [
    '/node_modules/(?!(@hotwired/stimulus)/)'
  ],
  testMatch: [
    '**/spec/javascript/**/*.spec.js',
    '**/spec/javascript/**/*.test.js'
  ],
  moduleNameMapper: {
    '^@hotwired/stimulus': '<rootDir>/node_modules/@hotwired/stimulus/dist/stimulus.js'
  },
  verbose: true
}
