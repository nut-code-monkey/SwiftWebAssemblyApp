import ElementaryUI

@View
struct AppView {
    @State var count = 0

    var body: some View {
        div(.class("container-fluid")) {
            h1 { "Hello from Swift WASM and ElementaryUI!" }
            p { "Count: \(count)" }
            button { "Increment" }
                .onClick { count += 1 }
        }
    }
}
