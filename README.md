# 軟硬體協同之一切

啟動專案的方法：

1. 打開 Vivado 2017.2 Tcl Shell
2. 在命令列輸入
```
cd <專案的位置>
source start.tcl
```
3. 然後你就建好硬體專案了
4. 實作硬體
5. 匯出硬體
6. 打開 SDK
7. 在 SDK 裡 File/Import -> 選 General/Existing Projects into Workspace -> 選 Select root directory，按下 Browse... 瀏覽 `專案目錄/srcs/sdk/find_face`，勾選 Copy projects into workspace -> 確定
8. 建立一個 Board Support Package，名稱設為 `find_face_bsp`，OS 設為 standalone
9. 設定 find_face 專案的 project references，選取 `find_face_bsp`
10. 設定 find_face_bsp 專案的 project references，選取 `design_1_wrapper_hw_platform_0`
11. 耶！完成了

## 作業 4

匯入的專案在 `專案目錄/srcs/sdk/dmatest` 和 `專案目錄/srcs/sdk/dmatest_bsp`
