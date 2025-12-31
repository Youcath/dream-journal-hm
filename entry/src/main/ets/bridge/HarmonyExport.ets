import { webview } from '@kit.ArkWeb';
import fs from '@ohos.file.fs';
import { picker } from '@kit.CoreFileKit';

export class HarmonyExport {
  private ctx: any;
  private controller: webview.WebviewController;

  constructor(ctx: any, controller: webview.WebviewController) {
    this.ctx = ctx;
    this.controller = controller;
  }

  // Web 端调用：window.HarmonyExport.exportData(jsonString)
  // 兼容：window.AndroidExport.exportData(jsonString)
  exportData(jsonString: string): void {
    // JSProxy 侧要求同步返回，这里内部启动异步流程
    (async () => {
      try {
        const filename = `dream_journal_backup_${this.formatDateTime(new Date())}.json`;

        // 系统保存对话框：默认打开下载目录（HarmonyOS 5.0.0+）
        const documentSaveOptions: any = new (picker as any).DocumentSaveOptions();
        documentSaveOptions.newFileNames = [filename];
        documentSaveOptions.fileSuffixChoices = ['.json'];
        documentSaveOptions.pickerMode = (picker as any).DocumentPickerMode?.DOWNLOAD;

        const documentViewPicker: any = new (picker as any).DocumentViewPicker(this.ctx);
        const result = await documentViewPicker.save(documentSaveOptions);
        const uri: string | undefined = Array.isArray(result) ? result[0] : result;

        if (!uri) {
          (this.controller as any)?.runJavaScript?.(
            `try{window.showToast&&window.showToast('已取消导出',2000);}catch(e){}`
          );
          return;
        }

        const fd = fs.openSync(uri, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
        fs.writeSync(fd.fd, jsonString);
        fs.closeSync(fd);

        (this.controller as any)?.runJavaScript?.(
          `try{window.showToast&&window.showToast('导出成功：${filename}',3500);}catch(e){}`
        );
        (this.controller as any)?.runJavaScript?.(`try{window.onExportComplete&&window.onExportComplete();}catch(e){}`);
      } catch (err) {
        (this.controller as any)?.runJavaScript?.(
          `try{window.showToast&&window.showToast('导出失败',4000,true);}catch(e){}`
        );
      }
    })();
  }

  private formatDateTime(d: Date): string {
    const pad2 = (n: number) => n.toString().padStart(2, '0');
    return `${d.getFullYear()}${pad2(d.getMonth() + 1)}${pad2(d.getDate())}_${pad2(d.getHours())}${pad2(d.getMinutes())}${pad2(d.getSeconds())}`;
  }
}


