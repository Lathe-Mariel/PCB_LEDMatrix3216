# PLL仕様書 (pll_spec.md)

## モジュール名
`pll_25m`

## ポート定義

| ポート名 | 方向 | 説明 |
|---------|------|------|
| `clkin` | input  | 入力クロック 50 MHz (システムクロック) |
| `clkout` | output | 出力クロック **25 MHz** |
| `lock`  | output | PLL ロック信号 (1 = ロック完了) |

## 要求仕様

| 項目 | 値 |
|------|----|
| 入力周波数 | 50 MHz |
| 出力周波数 | 25 MHz |
| 分周比 | ÷2 |
| 出力デューティ比 | 50% |
| `lock` 極性 | 正論理 (High = ロック完了) |

## Gowin IP Generator での設定手順 (Tang Primer 25K)

1. Gowin EDA を開き、**Tools → IP Core Generator** を起動
2. **rPLL** (Gowin FPGA用 PLL) を選択
3. 以下のパラメータを入力：

   | パラメータ | 設定値 |
   |-----------|--------|
   | Input Frequency | 50 MHz |
   | Output Frequency (CLKOUT) | 25 MHz |
   | Output Duty Cycle | 50% |
   | Phase Shift | 0° |
   | LOCK 出力 | 有効 |

4. モジュール名を `pll_25m` に設定
5. 生成された `.v` ファイルをプロジェクトに追加

## 生成されるモジュールの典型的な形式

```verilog
module pll_25m (
    input  clkin,   // 50 MHz
    output clkout,  // 25 MHz
    output lock
);

// Gowin rPLL instance (自動生成)
rPLL #(
    .FCLKIN("50"),
    .IDIV_SEL(0),     // 入力分周 = 1
    .FBDIV_SEL(0),    // フィードバック分周 = 1
    .ODIV_SEL(8),     // 出力分周 = 8  → 50/1*1/2 = 25 MHz
    // ※ 実際の設定値はGowin IP Generatorが自動計算します
    .CLKOUT_FT_DIR(1'b1),
    .CLKOUT_DLY_STEP(0),
    .CLKOUTP_FT_DIR(1'b1),
    .CLKOUTP_DLY_STEP(0),
    .CLKFB_SEL("internal"),
    .CLKOUT_BYPASS("false"),
    .CLKOUTP_BYPASS("false"),
    .CLKOUTD_BYPASS("false"),
    .DYN_IDIV_SEL("false"),
    .DYN_FBDIV_SEL("false"),
    .DYN_ODIV_SEL("false"),
    .DYN_SDIV_SEL(2),
    .DYN_DA_EN("true"),
    .DYN_OFFSET_SEL("false"),
    .DEVICE("GW5A-25")
) pll_inst (
    .CLKOUT(clkout),
    .LOCK(lock),
    .CLKOUTP(),
    .CLKOUTD(),
    .CLKOUTD3(),
    .RESET(1'b0),
    .RESET_P(1'b0),
    .CLKIN(clkin),
    .CLKFB(1'b0),
    .FBDSEL(6'b0),
    .IDSEL(6'b0),
    .ODSEL(6'b0),
    .PSDA(4'b0),
    .DUTYDA(4'b0),
    .FDLY(4'b0)
);

endmodule
```

> **注意**: 上記は参考例です。実際のパラメータ値は必ず Gowin IP Generator で
> 自動生成されたものを使用してください。デバイスは **GW5A-25** を選択してください。
