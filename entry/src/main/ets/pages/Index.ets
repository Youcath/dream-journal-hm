import { webview } from '@kit.ArkWeb';
import dataPreferences from '@ohos.data.preferences';

@Entry
@Component
struct Index {
  private controller: webview.WebviewController = new webview.WebviewController();
  @State private loadError: boolean = false;
  @State private isLoading: boolean = true;
  private storageBridge: HarmonyStorage | MemoryStorage = new MemoryStorage();

  aboutToAppear() {
    // 初始化 Web 引擎，确保页面可以正常加载
    webview.WebviewController.initializeWebEngine();

    // 创建持久化存储（同步 API），用于向 Web 注入 HarmonyStorage
    try {
      const ctx = getContext(this);
      // 新版 API 第二个参数为 Options
      const prefs = dataPreferences.getPreferencesSync(ctx, { name: 'dream_journal_storage' });
      this.storageBridge = new HarmonyStorage(prefs);
    } catch (err) {
      // 若获取失败则回落到内存存储，至少保证 API 可用
      console.error('init storage failed', JSON.stringify(err));
      this.storageBridge = new MemoryStorage();
    }
  }

  build() {
    Stack() {
      Web({
        src: 'https://xiaojia736.github.io/dream-journal/',
        controller: this.controller
      })
        .javaScriptAccess(true)
        .domStorageAccess(true)
        .javaScriptProxy({
          name: 'HarmonyStorage',
          object: this.storageBridge,
          methodList: ['getItem', 'setItem', 'removeItem'],
          controller: this.controller
        })
        .width('100%')
        .height('100%')
        .onPageBegin(() => {
          this.loadError = false;
          this.isLoading = true;
        })
        // onError 在新版本 WebAttribute 中不存在，改用更细粒度的错误回调
        .onErrorReceive(() => {
          this.loadError = true;
          this.isLoading = false;
        })
        // 页面加载完成后隐藏占位层（若你的 SDK 回调名不同，编译器会报错，我们再按报错名改）
        .onPageEnd(() => {
          this.isLoading = false;
        })

      if (this.loadError) {
        Column() {
          Text('网络连接失败')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(Color.White)
        .opacity(0.9)
      }

      if (!this.loadError && this.isLoading) {
        Column({ space: 12 }) {
          Image($r('app.media.startIcon'))
            .width(64)
            .height(64)
            .objectFit(ImageFit.Contain)
          Text('加载中…')
            .fontSize(16)
            .fontColor(Color.Black)
          LoadingProgress()
            .width(48)
            .height(48)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(Color.White)
      }
    }
    .width('100%')
    .height('100%')
  }
}

class HarmonyStorage {
  private prefs: dataPreferences.Preferences;

  constructor(prefs: dataPreferences.Preferences) {
    this.prefs = prefs;
  }

  getItem(key: string): string | null {
    try {
      if (!this.prefs.hasSync(key)) {
        return null;
      }
      const value = this.prefs.getSync(key, '');
      return value as string;
    } catch (err) {
      console.error('getItem failed', JSON.stringify(err));
      return null;
    }
  }

  setItem(key: string, value: string): void {
    try {
      this.prefs.putSync(key, value);
      this.prefs.flushSync();
    } catch (err) {
      console.error('setItem failed', JSON.stringify(err));
    }
  }

  removeItem(key: string): void {
    try {
      this.prefs.deleteSync(key);
      this.prefs.flushSync();
    } catch (err) {
      console.error('removeItem failed', JSON.stringify(err));
    }
  }
}

class MemoryStorage {
  private cache: Map<string, string> = new Map<string, string>();

  getItem(key: string): string | null {
    return this.cache.has(key) ? this.cache.get(key)! : null;
  }

  setItem(key: string, value: string): void {
    this.cache.set(key, value);
  }

  removeItem(key: string): void {
    this.cache.delete(key);
  }
}