# 大六壬古籍证据覆盖报告

> 由 `tool/daliuren_classics/validate.dart` 从结构化证据目录生成。
> `pending`、`disputed` 与 locator-only 条目不计入已批准完成度。

## 汇总

- 规则总数：474
- 非排除规则：471
- 可执行批准规则：5
- 可执行批准完成度：5 / 471
- 外部课例：7（A/B 批准 3，locator-only 4）
- 已登记 source：8

## 规则族覆盖

| 规则族 | 总数 | 批准 | 待核 | 排除 | 争议 | Locator-only | 可执行 |
|---|---:|---:|---:|---:|---:|---:|---:|
| pan | 8 | 7 | 1 | 0 | 0 | 0 | 5 |
| shenjiang | 6 | 4 | 2 | 0 | 0 | 2 | 0 |
| jiuzongmen | 9 | 0 | 9 | 0 | 0 | 0 | 0 |
| derivedFacts | 6 | 0 | 6 | 0 | 0 | 6 | 0 |
| shensha | 238 | 233 | 0 | 3 | 2 | 1 | 0 |
| kejing | 64 | 64 | 0 | 0 | 0 | 0 | 0 |
| bifa | 100 | 99 | 0 | 0 | 1 | 0 | 0 |
| nianming | 8 | 0 | 8 | 0 | 0 | 8 | 0 |
| classSpirit | 18 | 0 | 18 | 0 | 0 | 18 | 0 |
| judgment | 9 | 0 | 9 | 0 | 0 | 9 | 0 |
| timing | 8 | 0 | 8 | 0 | 0 | 8 | 0 |

## 证据等级

| 等级 | 规则数 | 可执行批准 |
|---|---:|---:|
| A | 0 | 0 |
| B | 412 | 5 |
| C | 47 | 0 |
| D | 15 | 0 |

## 外部课例

| Case ID | 状态 | 等级 | 影印页 |
|---|---|---|---|
| `dlr.case.duanan.han-taishou-pray-for-snow` | pendingScan | C | 无（locator-only） |
| `dlr.case.cunyan.dingchou-yiyou-pregnancy` | pendingScan | C | 无（locator-only） |
| `dlr.case.cunyan.renwu-bingxu-exam` | pendingScan | C | 无（locator-only） |
| `dlr.case.cunyan.wuzi-bingzi-promotion` | pendingScan | C | 无（locator-only） |
| `dlr.case.zhinan.renyin-guimao-liu-tuizhai` | approved | B | 有 |
| `dlr.case.zhinan.yiwei-jimao-feng-yunsheng` | approved | B | 有 |
| `dlr.case.zhinan.gengyin-gengchen-ma-lianzhuang` | approved | B | 有 |

## 未决异文

- `dlr.variant.shensha-zhi-hai-second-value`：unresolved；configurable=false。
- `dlr.variant.shensha-guan-identity`：unresolved；configurable=false。
- `dlr.variant.shensha-gushen-guchen-identity`：unresolved；configurable=false。
- `dlr.variant.bifa-076-wording`：unresolved；configurable=false。
- `dlr.variant.gui-ren-table`：unresolved；configurable=false。
- `dlr.variant.shehai-tie-break`：unresolved；configurable=false。
- `dlr.variant.bieze-yang-method`：unresolved；configurable=false。
- `dlr.variant.bazhuan-with-ke-label`：unresolved；configurable=false。
- `dlr.variant.fanyin-terminology`：rejected；configurable=false。

## 证据阻塞项

- pan 尚有 1 条待核或争议规则。
- shenjiang 尚有 2 条待核或争议规则。
- jiuzongmen 尚有 9 条待核或争议规则。
- derivedFacts 尚有 6 条待核或争议规则。
- shensha 尚有 2 条待核或争议规则。
- bifa 尚有 1 条待核或争议规则。
- nianming 尚有 8 条待核或争议规则。
- classSpirit 尚有 18 条待核或争议规则。
- judgment 尚有 9 条待核或争议规则。
- timing 尚有 8 条待核或争议规则。
- 大六壬断案影印本 尚无可引用的稳定影印 source。
- 六壬存验影印本 尚无可引用的稳定影印 source。
- 壬归 尚无可引用的稳定影印 source。
- 六壬粹言 尚无可引用的稳定影印 source。
- 大六壬探原 尚无可引用的稳定影印 source。

## 校验边界

- 本报告只证明结构、引用与证据门禁状态，不判断古文解释是否正确。
- OCR 与固定转录只用于定位；未回到影印页的条目保持 C/D，且不可 `executableApproved`。
- 原书断语只作历史文本对照，不作为现实预测真实性验收。
