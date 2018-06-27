# 軟硬體協同設計 Lab6 —— 加速找臉

*摘要：* 這個報告是介紹如何利用上課所學的技術，設計出軟硬體協同的系統來加速「find_face」程式。

## 一、簡介
「find_face」是老師提供的圖形匹配程式。
功能是，在 1920x1080 的照片裡找出 32x32 的臉部圖形，並回傳匹配度。
這個程式在找匹配之前，會對照片用 3x3 median filtering 預處理。
計算匹配度的方法是計算兩張圖形之間的 SAD (Sum of Absolute Difference)，也就是把對應的像素相減之後取絕對值，然後把這些絕對值加總。
SAD 越小，就表示圖形越相似。
「find_face」是純軟體，而且沒有做優化，因此有效能上的問題。
我可以利用 Lab1 所學的方法來尋找效能瓶頸，並嘗試用 ZedBoard 上的資源來加速，接著說明各種方法的效果以及資源使用率。
在 Lab 6 裡，我們會需要從一張照片裡找 4 張臉。

## 二、尋找效能瓶頸
在 Lab1 時，我有嘗試檢測效能，然而我當時使用實時時鐘 (real-time timer) 的方法有問題。
我決定計時的函數有 `matrix_to_array`、`insertion_sort` 和 `compute_sad`，加上老師已經計時的 `median3x3` 和 `match`。
計時的方法是使用 `XTime_GetTime` 取得 real-time timer 的時間，在每個呼叫子程序的位置前後都加上 `XTime_GetTime`，然後相減得到子程序的執行時間。

用 Release 模式來編譯的話，原始程式的執行結果是
```
1. Reading images ... done in 987 msec.
2. Median filtering ... done in 979 msec.
3. Face-matching ... done in 20251 msec.

** Found the face at (881, 826) with cost 3080
```
可見得老師已經寫好部份程序的計時。

加上 `matrix_to_array`、`insertion_sort` 和 `compute_sad` 的計時程式後，得到結果是
```
1. Reading images ... done in 983 msec.
2. Median filtering ... done in 1305 msec.
matrix_to_array takes 184ms
insertion_sort takes 959ms
3. Face-matching ... done in 20502 msec.

** Found the face at (881, 826) with cost 3080

compute_sad takes 20364ms
```
我發現計時程式有開銷 (overhead)，而且對 Median filtering 運算時間的影響已經不能忽略，大約 33%。
但是我發現，`compute_sad` 子程序花費的時間是我觀察的子程序裡花費最大的，所以我應該試圖優化它。

如果我在 `compute_sad` 的最內層計時，那會得到以下的結果
```
1. Reading images ... done in 984 msec.
2. Median filtering ... done in 1305 msec.
matrix_to_array takes 184ms
insertion_sort takes 959ms
3. Face-matching ... done in 230858 msec.

** Found the face at (881, 826) with cost 3080

compute_sad takes 230704ms
inner loop in compute_sad takes 101015ms
```
overhead 之大，導致大部分的時間都在計時了，而且這麼做有可能破壞編譯器的優化，所以我不能用這種方法計算 `compute_sad` 最內層迴圈的花費。

## 三、軟體加速
既然找出熱點 (hotspot) 是 `compute_sad`，那就來優化吧。

### 1. 我做 Lab1 提出的方法

在 Lab1 時，我把 compute_sad 程式設計成，若加總的過程，超過已找到的最小值，則跳出 compute_sad，以節省計算時間。
我還利用 Arm 的單指令流多資料流 (SIMD) 指令來加速。
Zedboard 上的處理器能夠支援 Arm 目前的最新 SIMD 技術，NEON。[\[3\]](#f3)
利用 gcc 編譯器的向量化優化，可以使程式使用 NEON 指令集，從而加速程式。
我使用的編譯器參數是 `-O3 -mfpu=neon`，`-O3` 表示優化等級，`-mfpu=neon` 表示目標支援 NEON，可以用 NEON 優化。
[\[1\]](#f1)

### 2. 自己寫 NEON intrinsics

參考 Arm 的官方文件 [\[2\]](#f2)，以及 gcc 的編譯結果後，我覺得我可以做的比 gcc 的自動向量化更好，所以我就自己寫 NEON intrinsics。
我的程式利用了臉的圖案總是 32x32 的特性，來優化 `compute_sad` 子程序。以下描述我的作法
1. 用 `vld1q_u8` 讀取一列的圖形，由於 `vld1q_u8` 可一次載入 16 個位元組，因此只要 4 次 `vld1q_u8` 就可以載入一列的臉和待比對的圖形。
2. 
 
### 3. 結果
以下只是找 1 張臉，我想到找 4 張臉的方法就是一張臉找完再找一張臉，不用重複做 Median filtering，因為是在同一張照片上找。
有 profiling 時，效能也許會變差，所以不再計算子程序的花費時間，以減少 overhead，也不包含讀取圖片的時間，因為那和 SD 卡的儲存方式以及效能有關，導致結果不能重現。

| 方法        | filtering | matching |
| ----------- | ---------:| --------:|
| 原程式      |     918ms |  20251ms |
| 方法1       |     833ms |   2886ms |
| 方法2 (-O2) |     979ms |   1767ms |
| 方法2 (-O3) |     833ms |   1760ms |
| 方法2 (-Os) |    1054ms |   1423ms |

其中必須要講的是，方法 2 並沒有指定優化的等級，所以我測試了幾種等級，結果發現，雖然 `-Os` 為了減少程式大小，會使大部分的程式變慢，但是卻讓 face matching 變快了，是三個測試過的等級裡最快的。
## 四、硬體加速

## 參考資料
<p id='f1'>
[1] Richard M. Stallman et al., "Using the GNU Compiler Collection".
 Free Software Foundation, Boston.
網址：https://gcc.gnu.org/onlinedocs/gcc-5.5.0/gcc/ARM-Options.html#ARM-Options
</p>
<p id='f2'>
[2] ARM Informaion Center, "ARM Compiler toolchain Compiler Reference".
Arm Limited. 1995-2018.
取自網頁：http://infocenter.arm.com/help/index.jsp?topic=/com.arm.doc.dui0491f/BABEDJFB.html
</p>
<p id='f3'>
[3]
http://zedboard.org/content/zedboard-0
</p>
