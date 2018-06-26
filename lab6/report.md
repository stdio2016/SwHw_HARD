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

## 二、尋找效能瓶頸
在 Lab1 時，我有嘗試檢測效能，然而我當時使用 realtime timer 的方法有問題。
我決定計時的函數有 `matrix_to_array`、`insertion_sort` 和 `compute_sad`，加上老師已經計時的 `median3x3` 和 `match`。

用 Release 模式來編譯的話，原始程式的執行結果是
```
1. Reading images ... done in 803 msec.
2. Median filtering ... done in 981 msec.
3. Face-matching ... done in 20251 msec.

** Found the face at (881, 826) with cost 3080
```
可見得老師已經寫好部份程序的計時。
我把這個結果設為基準 (baseline)，其他的設計都和這個結果做比較。
