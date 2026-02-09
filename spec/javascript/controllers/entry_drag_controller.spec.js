// Create mock functions
const mockOption = jest.fn()
const mockDestroy = jest.fn()

// Create mock Sortable instance
const mockSortable = {
  option: mockOption,
  destroy: mockDestroy
}

// Create mock constructor
const MockSortable = jest.fn(() => mockSortable)

import { Application } from '@hotwired/stimulus'
import EntryDragController from 'controllers/entry_drag_controller'

describe("EntryDragController", () => {
  let application
  let controller
  let availableEntriesTarget
  let ratedEntriesTarget
  let counterTarget
  let finalizeButtonTarget

  beforeEach(async () => {
    // Set up global Sortable mock
    global.Sortable = MockSortable

    // Clear mock calls
    MockSortable.mockClear()
    mockOption.mockClear()
    mockDestroy.mockClear()

    // Set up DOM
    document.body.innerHTML = `
      <div class="accordion">
        <div class="accordion-item">
          <h2 class="accordion-header">
            <button class="accordion-button" type="button" data-bs-toggle="collapse" data-bs-target="#collapseOne">
              Accordion Header
            </button>
          </h2>
          <div id="collapseOne" class="accordion-collapse collapse show">
            <div class="accordion-body">
              <div data-controller="entry-drag"
                   data-entry-drag-finalized-value="false"
                   data-entry-drag-required-count-value="3">
                <div data-entry-drag-target="availableEntries" data-contest-id="1">
                  <div class="drag-handle">Entry 1</div>
                  <div class="drag-handle">Entry 2</div>
                </div>
                <div data-entry-drag-target="ratedEntries" data-contest-id="1">
                  <div class="drag-handle">Entry 3</div>
                </div>
                <div data-entry-drag-target="counter">0/3</div>
                <button data-entry-drag-target="finalizeButton" disabled>Finalize</button>
              </div>
            </div>
          </div>
        </div>
      </div>
    `

    // Get DOM elements first
    availableEntriesTarget = document.querySelector('[data-entry-drag-target="availableEntries"]')
    ratedEntriesTarget = document.querySelector('[data-entry-drag-target="ratedEntries"]')
    counterTarget = document.querySelector('[data-entry-drag-target="counter"]')
    finalizeButtonTarget = document.querySelector('[data-entry-drag-target="finalizeButton"]')

    // Start Stimulus application
    application = Application.start()
    application.register("entry-drag", EntryDragController)

    // Wait for next tick to ensure controller is connected
    await new Promise(resolve => setTimeout(resolve, 0))

    // Get controller instance
    controller = application.getControllerForElementAndIdentifier(
      document.querySelector('[data-controller="entry-drag"]'),
      'entry-drag'
    )
  })

  afterEach(() => {
    application.stop()
    document.body.innerHTML = ''
    delete global.Sortable
  })

  describe("initialization", () => {
    it("initializes Sortable instances for both containers", () => {
      expect(MockSortable).toHaveBeenCalledTimes(2)
    })

    it("sets up correct Sortable options", () => {
      const calls = MockSortable.mock.calls
      expect(calls[0][1].group).toBeDefined()
      expect(calls[0][1].onMove).toBeDefined()
    })
  })

  describe("drag and drop functionality", () => {
    it("prevents dragging between different contest instances", () => {
      const event = {
        from: { closest: () => ({ id: 'accordion-1' }) },
        to: { closest: () => ({ id: 'accordion-2' }) }
      }
      const result = controller.handleMove(event)
      expect(result).toBe(false)
    })

    it("allows dragging within the same contest instance", () => {
      const event = {
        from: { closest: () => ({ id: 'accordion-1' }) },
        to: { closest: () => ({ id: 'accordion-1' }) }
      }
      const result = controller.handleMove(event)
      expect(result).toBe(true)
    })
  })

  describe("finalization", () => {
    it("disables dragging when finalized", async () => {
      controller.element.setAttribute('data-entry-drag-finalized-value', 'true')
      await new Promise(resolve => setTimeout(resolve, 0))

      expect(mockOption).toHaveBeenCalledWith('disabled', true)
    })
  })

  describe("showSuccessOverlay", () => {
    it("replaces overlay content with success state and 'Ranking recorded' text", () => {
      const card = document.createElement('div')
      card.setAttribute('data-entry-id', '42')
      card.style.position = 'relative'
      card.innerHTML = `
        <div class="entry-loading-overlay show">
          <div class="spinner-container">
            <div class="spinner-border"></div>
            <div class="status-text">Updating...</div>
          </div>
        </div>
      `
      document.body.appendChild(card)

      controller.showSuccessOverlay(card)

      const overlay = card.querySelector('.entry-loading-overlay')
      expect(overlay.classList.contains('success')).toBe(true)
      expect(overlay.textContent).toMatch(/Ranking recorded/)
      expect(overlay.querySelector('.bi-check-circle-fill')).not.toBeNull()

      document.body.removeChild(card)
    })
  })

  describe("UI updates", () => {
    it("updates counter and rank badges correctly", () => {
      // Add one entry to rated entries
      controller.ratedEntriesTarget.innerHTML = `
        <div class="card" data-entry-id="1">
          <div class="badge bg-info">Rank: 1</div>
        </div>
      `
      controller.updateUI(1)
      expect(controller.counterTarget.textContent).toBe('1/3')
    })

    it("enables finalize button when required count is met", () => {
      // Add three entries to rated entries
      controller.ratedEntriesTarget.innerHTML = `
        <div class="card" data-entry-id="1">
          <div class="badge bg-info">Rank: 1</div>
        </div>
        <div class="card" data-entry-id="2">
          <div class="badge bg-info">Rank: 2</div>
        </div>
        <div class="card" data-entry-id="3">
          <div class="badge bg-info">Rank: 3</div>
        </div>
      `
      controller.updateUI(3)
      expect(controller.finalizeButtonTarget.disabled).toBe(false)
    })
  })
})
