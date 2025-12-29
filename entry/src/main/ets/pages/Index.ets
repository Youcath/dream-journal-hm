import { webview } from '@kit.ArkWeb';

@Entry
@Component
struct Index {
  private controller: webview.WebviewController = new webview.WebviewController();

  aboutToAppear() {
    // 初始化 Web 引擎，确保页面可以正常加载
    webview.WebviewController.initializeWebEngine();
  }

  build() {
    Column() {
      Web({
        src: 'https://xiaojia736.github.io/dream-journal/',
        controller: this.controller
      })
        .width('100%')
        .height('100%')
    }
    .width('100%')
    .height('100%')
  }
}