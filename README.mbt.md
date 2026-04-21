# simpl

一个用 MoonBit 实现的解释型小语言，特点是：

- 动态类型
- 函数式（`fn`、闭包、高阶函数）
- 基于环境模型（词法作用域）
- AST Walker 求值
- 递归下降语法分析器

## 特性

- 值类型：`Int`、`Bool`、`String`、`nil`、闭包
- 表达式：
  - 字面量与变量
  - `let ... = ... in ...`
  - `if ... then ... else ...`
  - `fn(...) => ...`
  - 函数调用：`f(x, y)`
  - 一元运算：`-x`、`not x`
  - 二元运算：`+ - * / == < > and or && ||`
- 错误处理：使用 MoonBit `raise` 风格（`EvalError` / `ParseError`）

## 语法示例

```txt
let x = 10 in
let f = fn(y) => x + y in
if true then f(5) else 0
```

## 使用方式

### 1) 直接构造 AST 并求值

```moonbit nocheck
///|
let expr = @simpl.add(@simpl.int_lit(1), @simpl.int_lit(2))

///|
let value = @simpl.eval(expr) // VInt(3)
```

### 2) 从源码字符串解析并求值

```moonbit nocheck
///|
let value = @simpl.eval_source("1 + 2 * 3") // VInt(7)
```

## 对外 API（核心）

- 解释执行：
  - `eval(expr) -> Value raise`
  - `eval_with_env(expr, env) -> Value raise`
- 解析：
  - `parse(source) -> Expr raise`
  - `eval_source(source) -> Value raise`
- 测试辅助：
  - `eval_is_int / eval_is_bool / eval_is_string / eval_is_error`
  - `parse_is_ok / parse_is_error`
  - `eval_source_is_int / eval_source_is_error`

## 运行与测试

```powershell
moon check
moon test
moon info; moon fmt
```

## 当前限制

- 字符串暂不支持转义序列（按原样读取，直到下一个 `"`）
- 目前没有语句块、递归定义（如 `let rec`）、列表字面量等扩展语法
