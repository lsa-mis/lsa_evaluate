// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"
import * as bootstrap from "bootstrap"
import Sortable from "sortablejs"

import "trix"
import "@rails/actiontext"

window.Sortable = Sortable;
