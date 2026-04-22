import Elementary
import Foundation

@main
struct AppLoader: HTMLDocument {
    static func main() {
        // Отримуємо аргументи
        // [0] - шлях до бінарника, [1] - TargetName, [2] - OutputPath
        let arguments = ProcessInfo.processInfo.arguments

        guard arguments.count > 2 else {
            print("❌ Usage: SiteGenerator <TargetName> <OutputPath>")
            exit(1)
        }

        let targetName = arguments[1]
        let outputPathString = arguments[2]
        let outputURL = URL(fileURLWithPath: outputPathString)

        do {
            let html = AppLoader(
                title: "Swift WebAssembly App",
                loadingText: "Loading ...",
                css: "https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css",
                loader: "app.js",
                viewport: "width=device-width, initial-scale=1"
            ).render()

            try html.write(to: outputURL, atomically: true, encoding: .utf8)
            print("📄 Generated index.html for \(targetName) at \(outputURL.path)")
        } catch {
            print("❌ Failed to generate HTML: \(error)")
            exit(1)
        }
    }


    let title: String
    private let loadingText: String
    private let css: String?
    private let js: String
    private let viewport: String?

    init(
        title: String,
        loadingText: String,
        css: String?,
        loader js: String,
        viewport: String?
    ) {
        self.title = title
        self.loadingText = loadingText
        self.css = css
        self.js = js
        self.viewport = viewport
    }

    var head: some HTML {
        if let viewport = viewport {
            meta(.name("viewport"), .content(viewport))
        }

        style { loaderStyle }
        script(.type(.module), .src(js)) { }

        if let css = css {
            link(.rel(.stylesheet)).attributes(.href(css))
        }
    }

    var body: some HTML {
        div(.id("global-loader")) {
            p { loadingText }
            div(.class("spinner")) {}
        }
    }
}

let loaderStyle =
"""
#global-loader {
    position: fixed;
    inset: 0;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    z-index: 9999;
    gap: 16px;
    transition: opacity 0.3s ease-out;
    font-family: system-ui, -apple-system, sans-serif;
     
}
.spinner {
    width: 40px;
    height: 40px;
    border: 4px solid #f3f3f3;
    border-top: 4px solid #3498db;
    border-radius: 50%;
    animation: spin 1s linear infinite;
}
@keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
"""
