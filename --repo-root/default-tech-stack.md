# React to Electron Desktop Apps in 2025: A Practical Migration Guide

The React → Electron transition has matured significantly and is **notably smooth in 2025**, particularly with modern tooling like Vite integration. For your React + TypeScript + Vite stack, you can achieve a production-ready Electron app in days rather than weeks, but the key decision is choosing between **web-first with Electron wrapper** versus **Electron-first architecture**. Based on extensive research of real-world migrations, the transition smoothness depends heavily on this architectural choice upfront, with most successful projects using a modular hybrid approach that keeps platform-specific code minimal.

The development experience has dramatically improved with electron-vite offering near-instant hot module replacement for the renderer, sub-second restarts for the main process, and excellent TypeScript support across all three processes (main, preload, renderer). However, you'll face real trade-offs: your web app naturally talks to PostgreSQL over HTTP, but Electron apps typically use local SQLite—requiring either continued remote database calls or a hybrid offline-first architecture. **For apps already deployed on Hostinger VPS with Docker Compose, the web-first wrapper approach makes most sense**, allowing you to reuse your existing API infrastructure while adding desktop-specific features progressively.

## How smooth is the React → Electron transition?

The transition smoothness varies dramatically by approach. Modern tooling has eliminated most technical friction, but **architectural decisions matter far more than tooling**. Three distinct paths emerge from industry experience:

**The simple wrapper approach** takes an existing React web app and wraps it in an Electron BrowserWindow—achievable in under an hour. You point Electron at `localhost:3000` in development and load the built `index.html` in production. This works immediately but creates security vulnerabilities if you enable Node integration, performs poorly compared to native solutions, and misses most desktop-specific advantages. Slack's engineering team explicitly calls this pattern a "recipe for disaster" in their architecture retrospective.

**The local resources approach** involves extracting your React app into discrete modules, publishing them to a package registry, and bundling everything locally in the Electron app. Slack moved to this architecture after years of iteration, finding it "worth the tradeoffs for performance and maintainability." This delivers fast cold boot times, no network dependency, better code reuse, and genuinely feels native. The cost is requiring a package publishing pipeline, losing continuous deployment for the desktop app, and making monorepo versus multi-repo architectural decisions.

**The hybrid approach** ships a local snapshot of your modules while updating them remotely in the background, combining continuous deployment with fast boot times. This represents Slack's current direction but introduces complexity around dual update paths (shell updates versus module updates) and caching strategies. For your Hostinger VPS deployment, this could mean **keeping your web app as-is while the Electron version caches the built assets locally and syncs when online**.

Real-world migration timelines from developer case studies: solo developer converted Lyricistant web app to dual platform in **2-3 weeks**, FreeCodeCamp developer built taggr photo management app in **1 month starting lean**, and React Native Universal Monorepo achieved cross-platform compatibility in **3-4 weeks of experimentation**. The pattern is clear—**simple wrappers take days, production-ready architecture takes weeks**.

## Best starter templates for React + Electron + TypeScript + Vite

**Top recommendation: guasam/electron-react-app** provides the most comprehensive production-ready foundation. This template combines electron-vite, React 18, TypeScript, TailwindCSS, and Shadcn UI with type-safe IPC using Zod validation, custom titlebars, hot reload with full HMR, VS Code debugging configuration, and electron-builder for packaging. The repository is actively maintained and includes a "Conveyor" system for secure IPC that prevents the common security mistakes AI tools make. For your use case migrating from Hostinger VPS, this template's path alias support (`@/` imports) and pre-configured Prettier/ESLint match typical React development workflows.

**Security-focused alternative: cawa-93/vite-electron-builder** prioritizes maximum security with context isolation enabled by default, monorepo structure separating concerns, auto-update ready with GitHub releases, end-to-end tests with Playwright, and comprehensive code signing support. This template is framework-agnostic, meaning you can initialize with React, Vue, or Svelte. The interactive renderer initialization (`npm run init`) walks you through setup, making it easier to understand each piece rather than having opinions forced on you. Best for teams wanting full control and willing to invest in understanding the architecture.

**Official option: Electron Forge Vite-TypeScript template** (`npx create-electron-app@latest my-app --template=vite-typescript`) provides first-party support from the Electron team, multiple makers out-of-box for Squirrel, Zip, DMG, DEB, and RPM, and built-in packaging/publishing workflow. The template reached experimental status in v7.5.0 and represents the official recommendation for new projects in 2025. However, it requires more configuration than electron-vite alternatives and has fewer community examples, making troubleshooting harder.

**Simplest entry point: electron-vite official templates** (`npm create @quick-start/electron`) offer interactive framework selection with React/Vue/Svelte options, single configuration file controlling all three processes, and optimized Vite setup for fast builds. The documentation at electron-vite.org is excellent for understanding the tool, and builds are **2-3x faster than Webpack-based solutions**. For developers already familiar with Vite configuration, this represents the smallest conceptual leap.

Version compatibility requirements as of 2025: Node.js 18 or 20+ (required), Electron 28+ (latest stable), Vite 5+ (electron-vite 2.0 requires this), React 18+, and TypeScript 5+. Your current Vite setup already meets these requirements, making the transition smoother.

## Development workflow and hot module replacement

Electron's three-process architecture means HMR works differently for each: **renderer process gets full instant HMR via Vite** with sub-100ms update times, **preload scripts trigger hot reload** reloading the entire renderer in ~500ms without restarting Electron, and **main process requires hot restart** killing and restarting the Electron app in 1-2 seconds. This multi-speed update system feels natural once you understand what code lives where—UI changes are instant, bridge changes are fast, and window management changes need full restart.

Your typical development command becomes `npm run dev`, which starts the Vite dev server for the renderer on port 5173, compiles main and preload processes with Vite/esbuild, launches Electron loading the dev server URL, monitors all three processes with file watchers, and triggers appropriate reload/restart on changes. The development experience **feels nearly identical to web development** for React component work, with the main difference being occasional main process restarts when modifying window creation or app lifecycle code.

electron-vite streamlines this with a single configuration file combining all three processes, built-in smart defaults for output directories and entry points, SSR build for main/preload processes leveraging Vite 5+ capabilities, automatic package.json caching, and built-in hot reload for the main process. The configuration looks like this:

```typescript
// electron.vite.config.ts
export default defineConfig({
  main: {
    plugins: [externalizeDepsPlugin()],
    build: {
      rollupOptions: {
        external: ['serialport', 'sqlite3'] // Native modules
      }
    }
  },
  preload: {
    plugins: [externalizeDepsPlugin()]
  },
  renderer: {
    resolve: {
      alias: {
        '@': resolve('src/renderer')
      }
    },
    plugins: [react()]
  }
})
```

VS Code debugging works excellently with proper configuration, giving you breakpoints in both main and renderer processes, Chrome DevTools for the renderer by default in dev mode, and electron-log integration for production debugging. The performance difference compared to older Webpack-based Electron setups is dramatic—**developer feedback loops are 2-3x faster**, making Electron development feel as responsive as pure web development.

## electron-vite versus alternatives: which to choose

**electron-vite as an npm package** offers the simplest configuration with a single config file, best performance with 2x faster builds than alternatives, and version 2.0+ supporting Vite 5+ with SSR builds for main/preload processes. The architecture combines all three process configurations into one file with intelligent defaults. However, it has less community adoption than Electron Forge and fewer templates/examples since it's newer. The package is not official Electron tooling but is actively maintained and stable.

**Electron Forge with Vite plugin** provides official Electron tooling, complete build/package/publish workflow, multiple maker support out-of-box, and better documentation for publishing flows. It receives new Electron features fastest since it's first-party. The downsides include more verbose configuration requiring 3+ config files (forge.config.js, vite.main.config.mjs, vite.preload.config.mjs, vite.renderer.config.mjs), experimental status meaning breaking changes are possible, and higher memory usage from concurrent builds.

**Decision matrix for your use case**: choose electron-vite for new production apps prioritizing developer experience and build performance (recommended for most cases), choose Electron Forge for enterprise projects requiring official support and full pipeline integration, choose vite-plugin-electron for integrating Electron into an existing Vite project with maximum flexibility, and choose electron-vite for learning/experimenting due to fastest setup.

The **recommended hybrid approach** uses electron-vite for build tooling combined with electron-builder for packaging, giving you simplified configuration during development and maximum flexibility for distribution. This combination appears in popular templates like guasam/electron-react-app and represents the current community best practice in 2025.

## TypeScript configuration across three processes

Electron requires **separate TypeScript configurations** for Node.js environments (main and preload) versus browser environments (renderer). The recommended project structure separates concerns:

```
project-root/
├── src/
│   ├── main/          # Main process (Node.js)
│   ├── preload/       # Preload scripts (limited Node.js)
│   └── renderer/      # Renderer (Browser/React)
├── tsconfig.json          # Base config
├── tsconfig.node.json     # Main + Preload
└── tsconfig.web.json      # Renderer
```

Critical configuration differences: main/preload use `target: "ES2022"` for Node.js 18+ compatibility with `module: "commonjs"` for Node.js module system, while renderer uses `target: "ESNext"` for modern browsers with `module: "ESNext"` since Vite handles bundling. The renderer must include `jsx: "react-jsx"` for React 17+ transform, `isolatedModules: true` required by Vite, and `moduleResolution: "bundler"` for modern imports.

Essential settings across all configs: `skipLibCheck: true` required for electron-store and similar packages, `strict: true` for maximum type safety, `esModuleInterop: true` for CommonJS compatibility, and `resolveJsonModule: true` for importing JSON files. **Missing any of these causes cryptic TypeScript errors** that waste hours troubleshooting.

Type definitions bridge between processes using declaration files:

```typescript
// src/preload/index.d.ts
export interface ElectronAPI {
  openFile: () => Promise<string>
  saveFile: (content: string) => Promise<void>
}

declare global {
  interface Window {
    electron: ElectronAPI
  }
}
```

This gives you full IntelliSense in your React components when calling `window.electron.openFile()`, catching type errors at compile time instead of runtime. **For your existing TypeScript setup, you're already 80% there**—you just need to add the Node.js-specific configuration for main/preload.

## electron-builder versus electron-forge for packaging

**electron-builder dominates the ecosystem** with 14,317 GitHub stars versus 6,898 for Electron Forge, 621,832 weekly downloads versus 1,728, and vastly more community templates and Stack Overflow answers. It's the mature, battle-tested solution with comprehensive documentation and extensive customization options. The single configuration object in package.json or electron-builder.yml feels familiar to most developers, and cross-platform builds from a single machine work better than Forge.

**Electron Forge represents the official path forward** with first-party Electron team backing, better integration with Electron updates, and receiving new features first (ASAR integrity, universal builds, etc.). The Vite plugin reached experimental status in v7.5.0 and represents the official recommendation for new projects. The architecture using multiple packages (maker-squirrel, maker-zip, maker-deb, etc.) provides clearer separation of concerns, though it means more configuration files to manage.

**Feature comparison highlights**: both support auto-update, code signing, macOS notarization, and multi-platform builds. electron-builder has better cross-platform build support and typically produces smaller bundle sizes (150-200 MB DMG versus 285-320 MB for Forge with default settings). Electron Forge has official Vite integration and simpler full build pipeline. Configuration complexity differs significantly—electron-builder uses a single config object while Forge spreads configuration across multiple files.

**For your migration from web to desktop**, electron-builder makes more sense because you likely want maximum configurability for dual deployment scenarios, extensive customization for platform-specific needs, mature stable solution to avoid experimental breaking changes, better community resources for troubleshooting, and the common pattern of electron-vite + electron-builder used in top templates. If you prioritize official tooling and built-in Vite plugin, Electron Forge is viable, but expect more configuration work upfront.

Build times for a simple app: compilation takes 5-15 seconds, packaging for a single platform takes 30-60 seconds, and full multi-platform builds in CI take 3-10 minutes depending on infrastructure. **These timelines mean you can iterate on packaging during development**, unlike older Electron tooling where builds took many minutes.

## IPC patterns: communicating between main and renderer

Modern Electron uses **contextBridge and invoke/handle pattern** as the recommended approach. The renderer calls `ipcRenderer.invoke('channel-name', ...args)` which returns a Promise, the main process registers `ipcMain.handle('channel-name', async (event, ...args) => { return result })`, and the preload script exposes specific methods via `contextBridge.exposeInMainWorld()`. This pattern is asynchronous, type-safe when combined with TypeScript, and secure by default.

Example for file operations:

```typescript
// Main Process (main.ts)
ipcMain.handle('file:read', async (event, filePath) => {
  // Security: validate path is in allowed directory
  const userData = app.getPath('userData')
  const resolved = path.resolve(filePath)
  if (!resolved.startsWith(userData)) {
    throw new Error('Access denied')
  }
  return fs.promises.readFile(resolved, 'utf-8')
})

// Preload Script (preload.ts)
contextBridge.exposeInMainWorld('electronAPI', {
  readFile: (path: string) => ipcRenderer.invoke('file:read', path)
})

// React Component
const FileViewer = () => {
  const [content, setContent] = useState('')
  
  const loadFile = async (filePath: string) => {
    const data = await window.electronAPI.readFile(filePath)
    setContent(data)
  }
  
  return <div>{content}</div>
}
```

**Critical security principle**: never expose raw `ipcRenderer` to the renderer process. Each AI tool tested (Cursor, Copilot, Claude) makes this mistake frequently, suggesting patterns like `contextBridge.exposeInMainWorld('electron', { ipcRenderer })` which creates massive security vulnerabilities. Instead, expose specific, scoped methods that validate all inputs.

For main-to-renderer communication (push notifications, progress updates), use `webContents.send` from main and set up listeners in preload:

```typescript
// Main Process
mainWindow.webContents.send('download-progress', { percent: 50 })

// Preload
contextBridge.exposeInMainWorld('electronAPI', {
  onDownloadProgress: (callback: (progress: number) => void) =>
    ipcRenderer.on('download-progress', (_event, data) => callback(data.percent))
})

// React Component
useEffect(() => {
  const unsubscribe = window.electronAPI.onDownloadProgress((percent) => {
    setProgress(percent)
  })
  return unsubscribe // Critical: cleanup listener
}, [])
```

**Anti-patterns to avoid**: never use `ipcRenderer.sendSync` as it blocks the renderer thread causing UI freezes, never expose broad APIs allowing arbitrary channel access, always validate the IPC sender in main process handlers to prevent malicious frames from calling your APIs, and always remove event listeners in React's useEffect cleanup to prevent memory leaks.

## State management with Zustand/Pinia in Electron

Standard state management libraries don't natively support IPC, creating challenges when **state needs to cross process boundaries**. Three approaches solve this: using specialized bridges, custom IPC middleware, or keeping state entirely in the renderer.

**Zubridge/Zutron approach** provides ready-made solutions for Zustand in Electron with automatic synchronization across processes. The store lives in the main process as the source of truth, changes propagate to all renderer windows via IPC, and React components use familiar Zustand hooks. Installation is straightforward: `npm install zutron`, initialize bridge in main process with `mainZustandBridge(ipcMain, store, [mainWindow])`, expose handlers in preload via `preloadZustandBridge(ipcRenderer)`, and use `createUseStore` in React components.

**Custom middleware approach** gives you full control but requires more code. You manually sync state changes via IPC, handle conflicts when multiple windows update state, and implement your own serialization. This makes sense when you need fine-grained control over what syncs and when, want to minimize IPC traffic for performance, or have complex state transformations that don't serialize well.

**Renderer-only state** (simplest option) keeps Zustand/Redux entirely in the renderer process with no IPC synchronization. This works well when state is UI-specific and doesn't need persistence across app restarts, you're building a single-window app, or desktop-specific features don't require main process coordination. **For your existing React app, this is the easiest starting point**—your state management likely stays unchanged initially, adding main process coordination only when needed for desktop features.

**Recommendation for your PostgreSQL-backed app**: Keep your existing state management for UI and cached data, use IPC for operations requiring Node.js APIs (file system, system dialogs, native notifications), persist critical state via electron-store rather than localStorage for better reliability, and consider Redux Persist or similar if you need offline-first functionality. Since you're already talking to PostgreSQL over HTTP, your desktop app can continue that pattern initially—**no need to rewrite everything for local SQLite unless offline functionality is a priority**.

## Security architecture: context isolation and preload scripts

Modern Electron security is built on **three critical settings**: `nodeIntegration: false` (default since Electron 5) prevents renderer from directly accessing Node.js, `contextIsolation: true` (default since Electron 12) separates preload script context from web page context preventing web content from accessing Electron internals, and `sandbox: true` (default since Electron 20) uses OS-level process isolation limiting renderer access to system resources.

Your BrowserWindow configuration should look like:

```javascript
const mainWindow = new BrowserWindow({
  width: 1200,
  height: 800,
  webPreferences: {
    nodeIntegration: false,      // Never enable for remote content
    contextIsolation: true,       // Required for security
    sandbox: true,                // Recommended for production
    preload: path.join(__dirname, 'preload.js'),
    webSecurity: true,            // Never disable in production
    allowRunningInsecureContent: false
  }
})
```

**Preload scripts are the security bridge**. They run in an isolated context with limited Node.js access, use contextBridge to expose specific methods to the renderer, and validate all inputs before passing to main process. The pattern ensures the renderer never gets direct Node.js access while still enabling desktop features.

Critical security mistakes developers make: disabling contextIsolation or enabling nodeIntegration because AI suggests it or old tutorials show it, exposing entire ipcRenderer to renderer allowing arbitrary IPC messages, not validating IPC senders meaning any web frame including iframes can call your APIs, disabling webSecurity which removes same-origin policy protections, and using `shell.openExternal` with untrusted input enabling command injection.

**AI code generation creates security vulnerabilities 80% of the time** according to Stanford research. Claude, Copilot, and Cursor all frequently suggest `contextIsolation: false` in their generated code, expose raw ipcRenderer through contextBridge, skip sender validation in IPC handlers, and use outdated security patterns from training data. **You must manually review all AI-generated Electron security code** against the official Electron security checklist.

Content Security Policy adds another layer:

```html
<meta http-equiv="Content-Security-Policy" 
      content="default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'">
```

This restricts what resources the renderer can load, preventing malicious script injection even if an XSS vulnerability exists. For your Hostinger VPS app making API calls, you'll need to add your API domain to CSP: `connect-src 'self' https://api.yourdomain.com`.

## Common gotchas: CORS, file system, databases

**CORS issues plague Electron apps** because the renderer runs in a Chromium browser context with same-origin policy. The correct solution is **making API calls from the main process via IPC** rather than from the renderer, avoiding CORS entirely since it's a server-to-server request. Never set `webSecurity: false` in production—this disables same-origin policy and creates massive security holes. Instead, structure your code so the renderer calls IPC handlers, main process makes HTTP requests using axios/fetch, and responses return through IPC.

For your existing Hostinger VPS with PostgreSQL, this means:

```typescript
// Main Process
ipcMain.handle('api:fetchUsers', async () => {
  const response = await axios.get('https://api.yourdomain.com/users')
  return response.data
})

// React Component (renderer)
const users = await window.electronAPI.fetchUsers()
```

**File system access requires specific patterns**. Always use `app.getPath()` to access system directories safely, providing paths for userData (app-specific storage), desktop, documents, downloads, and temp. Never hardcode file paths—they differ across operating systems. On macOS, users must grant full disk access via Settings → Security → Privacy → Full Disk Access for system file operations.

**Environment variables don't work reliably** after packaging. `process.env.NODE_ENV` is often undefined in production builds. The solution is using electron-is-dev package (`const isDev = require('electron-is-dev')`), which reliably detects development versus production. Configure API endpoints based on this: `const apiURL = isDev ? 'http://localhost:3001' : 'https://production.example.com'`. For sensitive values like API keys, use dotenv with different files for development and production, or inject via electron-builder's extraMetadata.

**Database integration for desktop apps** means choosing between SQLite for local storage and PostgreSQL for remote. SQLite in Electron requires installing sqlite3 and @electron/rebuild, running entirely in the main process (never renderer for security), using IPC for all queries from React components, and storing the database file in `app.getPath('userData')`. PostgreSQL maintains your existing architecture of remote database access over HTTP, requires network connectivity, and offers easier multi-user collaboration.

**Hybrid approach for your use case**: Continue using PostgreSQL for multi-user data and API-driven features, add SQLite for offline functionality and local caching if needed, sync between local and remote when online, and allow the app to function with degraded features when offline. This incremental approach means **your initial Electron app works identically to the web version**, with offline capabilities added progressively.

## Deployment: auto-updates, code signing, distribution

**electron-updater provides auto-update functionality** with minimal configuration. Install the package, configure publishing target in electron-builder config (GitHub Releases is easiest), and implement update checking in your main process:

```javascript
const { autoUpdater } = require('electron-updater')

app.on('ready', () => {
  autoUpdater.checkForUpdatesAndNotify()
})

autoUpdater.on('update-downloaded', (info) => {
  dialog.showMessageBox({
    type: 'info',
    title: 'Update Ready',
    message: 'A new version has been downloaded. Restart to apply?',
    buttons: ['Restart', 'Later']
  }).then((result) => {
    if (result.response === 0) autoUpdater.quitAndInstall()
  })
})
```

Publishing to GitHub Releases requires setting `GH_TOKEN` environment variable and running `npm run build -- -p always`. Updates check for new releases automatically, download in the background, and prompt users to restart. **This provides Chrome-like auto-updates for your desktop app**, keeping users on the latest version without manual downloads.

**Code signing is mandatory for distribution**. On macOS, you need Apple Developer Program membership ($99/year), Developer ID Application certificate, and notarization for macOS 10.15+. electron-builder handles this automatically with proper environment variables: `APPLEID`, `APPLEIDPASS` (app-specific password), and `APPLE_ID_PROVIDER` (team ID). The notarization process takes 5-15 minutes per build and requires macOS to build/sign.

On Windows, code signing requires an EV (Extended Validation) certificate on FIPS 140 Level 2 compliant hardware. Popular providers include DigiCert (recommended for cloud-based signing), Sectigo, and SSL.com. Modern alternative is Azure Trusted Signing, which eliminates physical hardware requirements. Without code signing, **Windows Defender SmartScreen blocks your app** with scary warnings, dramatically reducing downloads.

**Multi-platform builds require platform-specific runners**. macOS builds only possible on macOS (for code signing), Windows builds possible on macOS/Linux with Wine, and Linux builds possible on any platform. GitHub Actions matrix builds solve this:

```yaml
strategy:
  matrix:
    os: [macos-latest, ubuntu-latest, windows-latest]
```

This builds for all platforms in parallel, uploads artifacts to GitHub releases, and automatically triggers when you publish a new release tag.

**Distribution file sizes are substantial**: macOS DMG 80-150 MB, Windows NSIS 60-120 MB, and Linux AppImage 80-140 MB. The Electron framework itself contributes ~120 MB (includes Chromium + Node.js), making your web app's 2-5 MB of code relatively small. Optimization strategies reduce this: move dev dependencies to devDependencies, enable asar compression, bundle main process code, remove source maps in production, tree shake unused code, lazy load heavy modules, and compress images. **Realistic expectation: 100-150 MB minimum per platform**.

## AI code generation: capabilities and critical limitations

**Current AI tools (Claude, Copilot, Cursor) reliably handle 70% of Electron code** but fail catastrophically on security and architecture. They excel at boilerplate generation (BrowserWindow setup, basic main.js structure, simple IPC patterns), common patterns (file system operations, window management, event handlers), and refactoring tasks. The success rate for standard patterns is around 70% based on 2024-2025 developer reports.

**Critical security mistakes AI makes consistently**:

1. **Disabling context isolation**: AI suggests `contextIsolation: false` and `nodeIntegration: true` because old tutorials in training data used this pattern. This creates massive security vulnerabilities.

2. **Exposing raw ipcRenderer**: Patterns like `contextBridge.exposeInMainWorld('electron', { ipcRenderer })` allow arbitrary IPC messages, enabling attackers to execute any main process functionality.

3. **No sender validation**: AI-generated IPC handlers rarely validate `event.sender`, meaning any web frame including malicious iframes can call your APIs.

4. **Using deprecated APIs**: Training data includes removed features like the remote module, old webPreferences syntax, and electron-prebuilt package name.

5. **Platform-agnostic code**: Generated code often works only on one OS, assumes Unix paths on Windows, forgets macOS menu bar behavior, and ignores Linux-specific considerations.

**Stanford study findings**: 80% of AI-assisted developers wrote less secure code with 3.5x more false confidence about security compared to manual development. **This is catastrophic for Electron where security mistakes enable arbitrary code execution**.

**Documentation patterns that improve AI output**:

Create a security requirements file explicitly stating never set contextIsolation false or nodeIntegration true, always use contextBridge for IPC, always validate IPC message senders, and never expose raw ipcRenderer. Document your architecture clearly defining main process responsibilities (lifecycle, window creation), renderer responsibilities (UI only, no Node.js), and preload responsibilities (secure IPC bridge only). Maintain a library of code examples showing correct patterns, and use TypeScript definitions with JSDoc comments describing security considerations.

**Effective prompts for Electron**: Bad prompt is "Create an Electron app"—too vague. Good prompt is "Create an Electron app following these requirements: use contextIsolation true, use contextBridge for IPC, main process in main.js, renderer uses preload.js, follow Electron security best practices from electronjs.org/docs/tutorial/security". The specificity dramatically improves output quality.

**Tool-specific observations**: Cursor has best project context awareness and Composer feature for multi-file edits, making it strongest for complex Electron projects. Copilot excels at inline suggestions and quick tasks, working well for boilerplate. Claude with extended thinking mode best for architecture planning, but recent 2025 projects show it creates architectural issues if not given clear direction upfront.

**The 70% problem means AI is a powerful accelerant but not a replacement** for Electron expertise. It's most valuable when paired with experienced developers who guide prompts and review output. For your migration from React web to Electron, AI tools can generate your initial main.js, preload.js, and electron-vite configuration quickly, but you must manually review all security-related code against the Electron security checklist.

## Real-world migration experiences and maintenance overhead

**Slack's architectural journey** represents the most documented production Electron migration. They tested four approaches: loading remote web app directly (insecure, rejected), remote isolation with preload scripts (CPU/memory overhead, slow), local resources with shared modules (chosen initially, "worth the tradeoffs"), and hybrid with local snapshots updating remotely (current direction). The key lesson is **"between what is right and what is easy"**—simple wrapper approaches fail at scale while proper architecture requires significant investment.

**Solo developer experience** from Lyricistant shows dual web/desktop codebase is achievable for smaller projects. The developer created a "Delegate" interface abstracting all platform-specific code, used Inversion of Control with Manager pattern for common functionality, and made UI code "absolutely no idea" what platform it's running on. **Migration took 2-3 weeks** implementing this abstraction layer. The takeaway is abstraction is key—Electron's IPC is problematic because it's coupled to Electron, but wrapping it in platform-agnostic interfaces solves this.

**Maintenance overhead of dual codebases** varies by approach. Separate codebases mean features built twice, coordination required for feature parity, lock-step releases needed, and higher time-to-market, though each platform has simple mental model. Shared monolithic codebases eliminate duplicate work but create cognitive overhead—**developers must consider both platforms for every feature**, making UX decisions more complex. From Slack's analysis, the most significant cost is "when building out a piece of the user interface, an engineer now needs to consider both the web and desktop experience, never just one."

**Monorepo strategies enable effective code sharing**. Nx monorepo provides single node_modules for all projects, effortless code sharing between apps, unified command execution, and easy navigation. Lerna offers similar benefits with lighter tooling. Turborepo optimizes build caching. Real developer feedback: "Monorepo makes my mind blow... close to impossible to share code between Angular Web App and Node Microservices before, now painless with monorepo." **For your React + TypeScript + Vite stack, Nx or Turborepo make most sense** as they have excellent Vite support.

**Performance reality**: Electron uses roughly 2x CPU and memory compared to the same content in Chrome due to full Chromium instance per app, additional Node.js runtime overhead, and multi-process architecture. Bundle sizes are 100-150 MB minimum versus 2-5 MB for web apps. Boot times are slower than native but faster than remote web with consistent performance regardless of network. **Well-designed Electron apps perform excellently**—VS Code and Figma prove this—but poor architecture creates sluggish experiences. Performance issues are typically architecture decisions not Electron itself.

## Practical migration paths for your stack

Your current setup (React + TypeScript + Vite on Hostinger VPS with Docker Compose and PostgreSQL) suggests **web-first with incremental desktop features** as the optimal path.

**Phase 1: Minimal Electron wrapper (1-2 weeks)**. Use electron-vite + React template to create shell, point development build at `localhost:3000` (your existing dev server), load production build from Vite's `dist/index.html`, keep all API calls to Hostinger PostgreSQL unchanged, add basic desktop features like native menus and system tray, and deploy with electron-builder. This gives you **a functioning desktop app with minimal changes to existing codebase**, validating demand before major investment.

**Phase 2: Desktop-specific features (2-4 weeks)**. Add file system integration for import/export, implement system notifications using Electron's native API, create keyboard shortcuts unavailable in web, add auto-updater for seamless updates, and implement proper security with contextIsolation and preload scripts. Your web app continues unchanged while desktop version gains native capabilities.

**Phase 3: Offline functionality if needed (4-8 weeks)**. Implement SQLite for local data caching, create sync mechanism between local SQLite and remote PostgreSQL, enable offline mode with degraded features, add conflict resolution for changes made offline, and use electron-store for persistent settings. This transforms your app to offline-first while maintaining web version's online-only model.

**Phase 4: Monorepo optimization (optional, 2-3 weeks)**. Extract shared components to packages/ui, extract shared business logic to packages/core, create packages/desktop for Electron-specific code, set up Nx or Turborepo for efficient builds, and establish unified development workflow. This pays off if actively developing both web and desktop versions long-term.

**Architecture recommendation: web-first with Electron wrapper** initially, evolving to hybrid modular approach over time. This matches your deployment model where the web app is the source of truth on Hostinger, desktop version starts as enhanced wrapper, desktop-specific features add value beyond web, offline functionality comes later if validated by users, and monorepo structure introduced when dual-platform development becomes significant overhead.

**Cost-benefit analysis**: Building desktop version takes 4-8 weeks initially (phases 1-2), ongoing maintenance adds 20-30% development time for dual-platform features, bundle size increases to 150+ MB versus 5 MB web, performance acceptable if designed well (see VS Code), user reach expands to desktop-primary users, and native integrations provide competitive advantages. **The desktop version should solve real user problems** (offline access, file system integration, better performance) rather than existing just to have a desktop app.

For your specific case, the transition is smooth technically but requires strategic thinking about **why users want a desktop version**. If the answer is offline access or file system integration, Electron makes sense. If it's just "presence on desktop," a PWA might suffice with far less complexity. The mature tooling in 2025 means the technical transition is straightforward—the harder question is whether the desktop version creates sufficient value to justify ongoing maintenance overhead.