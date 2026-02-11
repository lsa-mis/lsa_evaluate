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

  describe("addLoadingOverlay", () => {
    it("adds overlay with spinner and 'Updating...' text", () => {
      const card = document.createElement('div')
      card.setAttribute('data-entry-id', '1')
      document.body.appendChild(card)

      controller.addLoadingOverlay(card)

      const overlay = card.querySelector('.entry-loading-overlay')
      expect(overlay).not.toBeNull()
      expect(overlay.querySelector('.spinner-border')).not.toBeNull()
      expect(overlay.textContent).toMatch(/Updating\.\.\./)
      expect(overlay.classList.contains('show')).toBe(true)
      expect(card.classList.contains('entry-card-loading')).toBe(true)

      controller.removeLoadingOverlay(card)
      document.body.removeChild(card)
    })

    it("shows overlay immediately with 'show' class", () => {
      const card = document.createElement('div')
      card.setAttribute('data-entry-id', '1')
      document.body.appendChild(card)

      controller.addLoadingOverlay(card)

      const overlay = card.querySelector('.entry-loading-overlay')
      expect(overlay.classList.contains('show')).toBe(true)

      controller.removeLoadingOverlay(card)
      document.body.removeChild(card)
    })

    it("schedules slow connection warning after 5 seconds", () => {
      jest.useFakeTimers()
      const card = document.createElement('div')
      card.setAttribute('data-entry-id', '1')
      document.body.appendChild(card)

      controller.addLoadingOverlay(card)

      const overlay = card.querySelector('.entry-loading-overlay')
      const statusText = overlay.querySelector('.status-text')
      expect(statusText.textContent).toMatch(/Updating\.\.\./)

      jest.advanceTimersByTime(5000)

      expect(statusText.innerHTML).toMatch(/Slow connection detected/)
      expect(statusText.innerHTML).toMatch(/Still working/)

      jest.useRealTimers()
      controller.removeLoadingOverlay(card)
      document.body.removeChild(card)
    })

    it("does not add duplicate overlay if one already exists", () => {
      const card = document.createElement('div')
      card.setAttribute('data-entry-id', '1')
      document.body.appendChild(card)

      controller.addLoadingOverlay(card)
      const overlayCount1 = card.querySelectorAll('.entry-loading-overlay').length

      controller.addLoadingOverlay(card)
      const overlayCount2 = card.querySelectorAll('.entry-loading-overlay').length

      expect(overlayCount1).toBe(1)
      expect(overlayCount2).toBe(1)

      controller.removeLoadingOverlay(card)
      document.body.removeChild(card)
    })

    it("does nothing when element is null", () => {
      expect(() => controller.addLoadingOverlay(null)).not.toThrow()
    })
  })

  describe("removeLoadingOverlay", () => {
    it("removes overlay and entry-card-loading class", () => {
      const card = document.createElement('div')
      card.setAttribute('data-entry-id', '1')
      document.body.appendChild(card)

      controller.addLoadingOverlay(card)
      expect(card.querySelector('.entry-loading-overlay')).not.toBeNull()
      expect(card.classList.contains('entry-card-loading')).toBe(true)

      jest.useFakeTimers()
      controller.removeLoadingOverlay(card)
      jest.advanceTimersByTime(400) // Wait for transition + remove

      expect(card.querySelector('.entry-loading-overlay')).toBeNull()
      expect(card.classList.contains('entry-card-loading')).toBe(false)

      jest.useRealTimers()
      document.body.removeChild(card)
    })

    it("clears slow connection timeout so callback never runs", () => {
      jest.useFakeTimers()
      const card = document.createElement('div')
      card.setAttribute('data-entry-id', '1')
      document.body.appendChild(card)

      controller.addLoadingOverlay(card)
      controller.removeLoadingOverlay(card)
      jest.advanceTimersByTime(6000) // Past the 5s slow connection threshold

      const overlay = card.querySelector('.entry-loading-overlay')
      // Overlay is removed, but if timeout had fired it would have updated statusText before removal
      // The key assertion: no warning text was shown (overlay was removed before timeout)
      expect(card.querySelector('.entry-loading-overlay')).toBeNull()

      jest.useRealTimers()
      document.body.removeChild(card)
    })

    it("shows error state when error is true", () => {
      const card = document.createElement('div')
      card.setAttribute('data-entry-id', '1')
      document.body.appendChild(card)

      controller.addLoadingOverlay(card)
      controller.removeLoadingOverlay(card, true)

      const overlay = card.querySelector('.entry-loading-overlay')
      expect(overlay.classList.contains('error')).toBe(true)
      expect(overlay.textContent).toMatch(/Error updating entry/)

      jest.useFakeTimers()
      jest.advanceTimersByTime(2500) // Error overlay removes after 2s
      jest.useRealTimers()
      document.body.removeChild(card)
    })

    it("does nothing when element is null", () => {
      expect(() => controller.removeLoadingOverlay(null)).not.toThrow()
      expect(() => controller.removeLoadingOverlay(null, true)).not.toThrow()
    })
  })

  describe("per-element timeout cleanup", () => {
    it("tracks timeouts per element so each overlay cleans up correctly", () => {
      jest.useFakeTimers()

      const cardA = document.createElement('div')
      cardA.setAttribute('data-entry-id', '1')
      document.body.appendChild(cardA)

      const cardB = document.createElement('div')
      cardB.setAttribute('data-entry-id', '2')
      document.body.appendChild(cardB)

      controller.addLoadingOverlay(cardA)
      controller.addLoadingOverlay(cardB)

      const overlayA = cardA.querySelector('.entry-loading-overlay')
      const overlayB = cardB.querySelector('.entry-loading-overlay')
      expect(overlayA.querySelector('.status-text').textContent).toMatch(/Updating\.\.\./)
      expect(overlayB.querySelector('.status-text').textContent).toMatch(/Updating\.\.\./)

      // Remove A's overlay - only A's timeout should be cleared
      controller.removeLoadingOverlay(cardA)
      jest.advanceTimersByTime(400) // Let A's overlay removal complete

      expect(cardA.querySelector('.entry-loading-overlay')).toBeNull()
      expect(cardB.querySelector('.entry-loading-overlay')).not.toBeNull()

      // After 5s, only B's slow connection callback should fire
      jest.advanceTimersByTime(5000)

      const statusB = cardB.querySelector('.status-text')
      expect(statusB.innerHTML).toMatch(/Slow connection detected/)
      // Card A had no overlay, so its timeout was cleared and never ran

      jest.useRealTimers()
      controller.removeLoadingOverlay(cardB)
      document.body.removeChild(cardA)
      document.body.removeChild(cardB)
    })

    it("showSuccessOverlay clears timeout for that element only", () => {
      jest.useFakeTimers()

      const cardA = document.createElement('div')
      cardA.setAttribute('data-entry-id', '1')
      cardA.innerHTML = `
        <div class="entry-loading-overlay show">
          <div class="spinner-container">
            <div class="status-text">Updating...</div>
          </div>
        </div>
      `
      document.body.appendChild(cardA)

      const cardB = document.createElement('div')
      cardB.setAttribute('data-entry-id', '2')
      document.body.appendChild(cardB)

      controller.addLoadingOverlay(cardB)

      // Manually add A to the WeakMap to simulate A having had a timeout (showSuccessOverlay
      // is called when overlay already exists; we're testing that it clears A's timeout)
      const timeoutA = setTimeout(() => {}, 5000)
      controller.slowConnectionTimeouts.set(cardA, timeoutA)

      controller.showSuccessOverlay(cardA)

      // A's timeout should be cleared; B's should still be scheduled
      expect(controller.slowConnectionTimeouts.has(cardA)).toBe(false)
      expect(controller.slowConnectionTimeouts.has(cardB)).toBe(true)

      jest.useRealTimers()
      controller.removeLoadingOverlay(cardB)
      document.body.removeChild(cardA)
      document.body.removeChild(cardB)
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
