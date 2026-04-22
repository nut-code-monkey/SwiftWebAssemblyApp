import { init } from "../../.build/plugins/PackageToJS/outputs/Package/index.js";

async function launch(wasmName) {
    try {
        await init({
            module: fetch(new URL(wasmName, import.meta.url)),
            getImports: () => ({})
        });

        document.getElementById("global-loader")?.remove();

    } catch (error) {
        console.error("WASM loading error:", error);
        const loader = document.getElementById("global-loader");
        if (loader) {
            loader.innerText = "Loading error:"  + error.message + " ❌";
        }
    }
}

launch("app.wasm");
