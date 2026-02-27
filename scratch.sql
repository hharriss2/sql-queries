import XLSX from "xlsx-js-style"
import fs from "fs"

export default defineComponent({
  name: "Create Structured Excel Report",
  type: "action",
  props: {
    top_budget_table: { type: "object" },
    customer_sales: { type: "object" },
    department_sales: { type: "object" }
  },

  async run({ $ }) {

    const budgetData = this.top_budget_table
    const salesData = this.customer_sales
    const departmentData = this.department_sales

    const wb = XLSX.utils.book_new()
    const ws = {}

    const colors = {
      lightBlue: "ADD8E6",
      lightGrey: "D3D3D3",
      lightOrange: "FFD580",
      darkerGrey: "A9A9A9",
      yellow: "FFFF00",
      lightRed: "FFB6C1",
      green: "90EE90"
    }

    const monthColors = {
      Jan: colors.lightBlue, Feb: colors.lightBlue, Mar: colors.lightBlue,
      Apr: colors.lightGrey, May: colors.lightGrey, Jun: colors.lightGrey,
      Jul: colors.lightOrange, Aug: colors.lightOrange, Sep: colors.lightOrange,
      Oct: colors.darkerGrey, Nov: colors.darkerGrey, Dec: colors.darkerGrey
    }

    // -------- cell helper ----------
    const createCell = (value, style = {}) => {
      const isNumber = typeof value === "number" && !isNaN(value)

      return {
        v: value,
        t: isNumber ? "n" : "s",
        s: {
          border: {
            top: { style: "thin", color: { rgb: "000000" }},
            bottom: { style: "thin", color: { rgb: "000000" }},
            left: { style: "thin", color: { rgb: "000000" }},
            right: { style: "thin", color: { rgb: "000000" }}
          },
          ...(isNumber ? { numFmt: "$#,##0" } : {}),
          ...style
        }
      }
    }

    let currentRow = 1
    ws["!merges"] = []

    // =========================
    // BUDGET TABLE
    // =========================
    if (budgetData?.length) {

      const headers = Object.keys(budgetData[0])

      headers.forEach((header, c) => {

        const displayHeader = header === "date_row" ? "" : header

        let style = {
          font: { bold: true },
          alignment: { horizontal: "center" }
        }

        const m = Object.keys(monthColors).find(x => header.includes(x))
        if (m) style.fill = { patternType: "solid", fgColor: { rgb: monthColors[m] }}
        if (header.toLowerCase().includes("total"))
          style.fill = { patternType: "solid", fgColor: { rgb: colors.yellow }}

        ws[XLSX.utils.encode_cell({ r: currentRow, c })] =
          createCell(displayHeader, style)
      })

      currentRow++

      budgetData.forEach((row, i) => {

        headers.forEach((h, c) => {

          const val = row[h]
          const rowLabel = row[headers[0]] || ""

          let style = {}

          if (typeof rowLabel === "string" &&
            (rowLabel.includes("2025 Actual") || rowLabel.includes("2026 Actual"))) {
            style = {
              font: { bold: true },
              fill: { patternType: "solid", fgColor: { rgb: colors.yellow }}
            }
          }

          ws[XLSX.utils.encode_cell({ r: currentRow + i, c })] =
            createCell(val, style)
        })
      })

      currentRow += budgetData.length + 2
    }

    // =========================
    // CUSTOMER SALES TABLE
    // =========================
    if (salesData?.length) {

      const allHeaders = Object.keys(salesData[0]).filter(h => h !== "date_row")
      const breakoffColumns = ['DI', 'DI %', 'Domestic', 'DOM %', 'Q1', 'Q2', 'Q3', 'Q4']
      
      const baseHeaders = allHeaders.filter(h => !breakoffColumns.includes(h))
      const breakoffHeaders = allHeaders.filter(h => breakoffColumns.includes(h))

      const salesHeaders = [
        ...baseHeaders,
        "Var_Budget_$",
        "Var_Budget_%",
        "Var_Prior_$",
        "Var_Prior_%"
      ]

      const totalCols = salesHeaders.length
      const startColForBreakoff = totalCols + 1

      // ---- Full Year merged title ----
      ws[XLSX.utils.encode_cell({ r: currentRow, c: 0 })] =
        createCell("Full Year 2026", {
          font: { bold: true, size: 14 },
          alignment: { horizontal: "center" }
        })

      ws["!merges"].push({
        s: { r: currentRow, c: 0 },
        e: { r: currentRow, c: totalCols - 1 }
      })

      currentRow += 2

      // ---- MAIN TABLE grouped header row (only variance headers) ----
      for (let c = 0; c < baseHeaders.length; c++) {
        ws[XLSX.utils.encode_cell({ r: currentRow, c })] = createCell("", {})
      }

      ws[XLSX.utils.encode_cell({ r: currentRow, c: baseHeaders.length })] =
        createCell("Variance to Budget", { 
          font: { bold: true }, 
          alignment: { horizontal: "center" },
          fill: { patternType: "solid", fgColor: { rgb: colors.lightOrange }}
        })

      ws[XLSX.utils.encode_cell({ r: currentRow, c: baseHeaders.length + 2 })] =
        createCell("Variance to Prior", { 
          font: { bold: true }, 
          alignment: { horizontal: "center" },
          fill: { patternType: "solid", fgColor: { rgb: colors.green }}
        })

      ws["!merges"].push({
        s: { r: currentRow, c: baseHeaders.length },
        e: { r: currentRow, c: baseHeaders.length + 1 }
      })

      ws["!merges"].push({
        s: { r: currentRow, c: baseHeaders.length + 2 },
        e: { r: currentRow, c: baseHeaders.length + 3 }
      })

      // ---- BREAKOFF TABLE grouped header row ----
      // Add 'DOM' merged header above Q1-Q4
      const q1Index = breakoffHeaders.indexOf('Q1')
      if (q1Index !== -1) {
        ws[XLSX.utils.encode_cell({ r: currentRow, c: startColForBreakoff + q1Index })] =
          createCell("DOM", {
            font: { bold: true },
            alignment: { horizontal: "center" },
            fill: { patternType: "solid", fgColor: { rgb: colors.yellow }}
          })

        ws["!merges"].push({
          s: { r: currentRow, c: startColForBreakoff + q1Index },
          e: { r: currentRow, c: startColForBreakoff + q1Index + 3 }
        })
      }

      currentRow++

      // ---- MAIN TABLE sub headers ($ / %) ----
      salesHeaders.forEach((h, c) => {

        let label = h
        if (h.includes("Var_") && h.includes("$")) label = "$"
        if (h.includes("Var_") && h.includes("%")) label = "%"

        let style = { 
          font: { bold: true }, 
          alignment: { horizontal: "center" }
        }

        if (h === "Budget") {
          style.fill = { patternType: "solid", fgColor: { rgb: colors.lightGrey }}
        } else if (h === "Actuals") {
          style.fill = { patternType: "solid", fgColor: { rgb: colors.lightRed }}
        } else if (h === "Prior") {
          style.fill = { patternType: "solid", fgColor: { rgb: colors.yellow }}
        } else if (h.includes("Var_Budget_")) {
          style.fill = { patternType: "solid", fgColor: { rgb: colors.lightOrange }}
        } else if (h.includes("Var_Prior_")) {
          style.fill = { patternType: "solid", fgColor: { rgb: colors.green }}
        }

        ws[XLSX.utils.encode_cell({ r: currentRow, c })] =
          createCell(label, style)
      })

      // ---- BREAKOFF TABLE headers ----
      breakoffHeaders.forEach((h, c) => {
        ws[XLSX.utils.encode_cell({ r: currentRow, c: startColForBreakoff + c })] =
          createCell(h, {
            font: { bold: true },
            alignment: { horizontal: "center" },
            fill: { patternType: "solid", fgColor: { rgb: colors.yellow }}
          })
      })

      currentRow++

      // ---- MAIN TABLE data rows ----
      salesData.forEach((row, i) => {

        const actual = Number(row["Actuals"] || 0)
        const budget = Number(row["Budget"] || 0)
        const prior = Number(row["Prior"] || 0)

        const varBudget = actual - budget
        const pctBudget = budget ? varBudget / budget : 0

        const varPrior = actual - prior
        const pctPrior = prior ? varPrior / prior : 0

        const values = [
          ...baseHeaders.map(h => row[h]),
          varBudget,
          pctBudget,
          varPrior,
          pctPrior
        ]

        values.forEach((v, c) => {

          let style = {}

          const headerName = salesHeaders[c]
          if (headerName === "Budget") {
            style.fill = { patternType: "solid", fgColor: { rgb: colors.lightGrey }}
          } else if (headerName === "Actuals") {
            style.fill = { patternType: "solid", fgColor: { rgb: colors.lightRed }}
          } else if (headerName === "Prior") {
            style.fill = { patternType: "solid", fgColor: { rgb: colors.yellow }}
          } else if (headerName.includes("Var_Budget_")) {
            style.fill = { patternType: "solid", fgColor: { rgb: colors.lightOrange }}
          } else if (headerName.includes("Var_Prior_")) {
            style.fill = { patternType: "solid", fgColor: { rgb: colors.green }}
          }

          if (salesHeaders[c].includes("%"))
            style.numFmt = "0%"

          ws[XLSX.utils.encode_cell({ r: currentRow + i, c })] =
            createCell(v, style)
        })

        // ---- BREAKOFF TABLE data rows ----
        breakoffHeaders.forEach((h, c) => {
          const value = row[h]
          let style = {}

          if (h.includes('%')) {
            style.numFmt = "0%"
          } else {
            style.numFmt = "$#,##0"
          }

          ws[XLSX.utils.encode_cell({ r: currentRow + i, c: startColForBreakoff + c })] =
            createCell(value, style)
        })
      })

      currentRow += salesData.length + 2
    }

    // =========================
    // DEPARTMENT SALES TABLE
    // =========================
    if (departmentData?.length) {

      const allHeaders = Object.keys(departmentData[0]).filter(h => h !== "date_row")
      const breakoffColumns = ['DI', 'DI %', 'Domestic', 'DOM %', 'Q1', 'Q2', 'Q3', 'Q4']
      
      const baseHeaders = allHeaders.filter(h => !breakoffColumns.includes(h))
      const breakoffHeaders = allHeaders.filter(h => breakoffColumns.includes(h))

      const departmentHeaders = [
        ...baseHeaders,
        "Var_Budget_$",
        "Var_Budget_%",
        "Var_Prior_$",
        "Var_Prior_%"
      ]

      const totalCols = departmentHeaders.length
      const startColForBreakoff = totalCols + 1

      // ---- Full Year merged title ----
      ws[XLSX.utils.encode_cell({ r: currentRow, c: 0 })] =
        createCell("Department Sales - Full Year 2026", {
          font: { bold: true, size: 14 },
          alignment: { horizontal: "center" }
        })

      ws["!merges"].push({
        s: { r: currentRow, c: 0 },
        e: { r: currentRow, c: totalCols - 1 }
      })

      currentRow += 2

      // ---- MAIN TABLE grouped header row (only variance headers) ----
      for (let c = 0; c < baseHeaders.length; c++) {
        ws[XLSX.utils.encode_cell({ r: currentRow, c })] = createCell("", {})
      }

      ws[XLSX.utils.encode_cell({ r: currentRow, c: baseHeaders.length })] =
        createCell("Variance to Budget", { 
          font: { bold: true }, 
          alignment: { horizontal: "center" },
          fill: { patternType: "solid", fgColor: { rgb: colors.lightOrange }}
        })

      ws[XLSX.utils.encode_cell({ r: currentRow, c: baseHeaders.length + 2 })] =
        createCell("Variance to Prior", { 
          font: { bold: true }, 
          alignment: { horizontal: "center" },
          fill: { patternType: "solid", fgColor: { rgb: colors.green }}
        })

      ws["!merges"].push({
        s: { r: currentRow, c: baseHeaders.length },
        e: { r: currentRow, c: baseHeaders.length + 1 }
      })

      ws["!merges"].push({
        s: { r: currentRow, c: baseHeaders.length + 2 },
        e: { r: currentRow, c: baseHeaders.length + 3 }
      })

      // ---- BREAKOFF TABLE grouped header row ----
      // Add 'DOM' merged header above Q1-Q4
      const q1Index = breakoffHeaders.indexOf('Q1')
      if (q1Index !== -1) {
        ws[XLSX.utils.encode_cell({ r: currentRow, c: startColForBreakoff + q1Index })] =
          createCell("DOM", {
            font: { bold: true },
            alignment: { horizontal: "center" },
            fill: { patternType: "solid", fgColor: { rgb: colors.yellow }}
          })

        ws["!merges"].push({
          s: { r: currentRow, c: startColForBreakoff + q1Index },
          e: { r: currentRow, c: startColForBreakoff + q1Index + 3 }
        })
      }

      currentRow++

      // ---- MAIN TABLE sub headers ($ / %) ----
      departmentHeaders.forEach((h, c) => {

        let label = h
        if (h.includes("Var_") && h.includes("$")) label = "$"
        if (h.includes("Var_") && h.includes("%")) label = "%"

        let style = { 
          font: { bold: true }, 
          alignment: { horizontal: "center" }
        }

        if (h === "Budget") {
          style.fill = { patternType: "solid", fgColor: { rgb: colors.lightGrey }}
        } else if (h === "Actuals") {
          style.fill = { patternType: "solid", fgColor: { rgb: colors.lightRed }}
        } else if (h === "Prior") {
          style.fill = { patternType: "solid", fgColor: { rgb: colors.yellow }}
        } else if (h.includes("Var_Budget_")) {
          style.fill = { patternType: "solid", fgColor: { rgb: colors.lightOrange }}
        } else if (h.includes("Var_Prior_")) {
          style.fill = { patternType: "solid", fgColor: { rgb: colors.green }}
        }

        ws[XLSX.utils.encode_cell({ r: currentRow, c })] =
          createCell(label, style)
      })

      // ---- BREAKOFF TABLE headers ----
      breakoffHeaders.forEach((h, c) => {
        ws[XLSX.utils.encode_cell({ r: currentRow, c: startColForBreakoff + c })] =
          createCell(h, {
            font: { bold: true },
            alignment: { horizontal: "center" },
            fill: { patternType: "solid", fgColor: { rgb: colors.yellow }}
          })
      })

      currentRow++

      // ---- MAIN TABLE data rows ----
      departmentData.forEach((row, i) => {

        const actual = Number(row["Actuals"] || 0)
        const budget = Number(row["Budget"] || 0)
        const prior = Number(row["Prior"] || 0)

        const varBudget = actual - budget
        const pctBudget = budget ? varBudget / budget : 0

        const varPrior = actual - prior
        const pctPrior = prior ? varPrior / prior : 0

        const values = [
          ...baseHeaders.map(h => row[h]),
          varBudget,
          pctBudget,
          varPrior,
          pctPrior
        ]

        values.forEach((v, c) => {

          let style = {}

          const headerName = departmentHeaders[c]
          if (headerName === "Budget") {
            style.fill = { patternType: "solid", fgColor: { rgb: colors.lightGrey }}
          } else if (headerName === "Actuals") {
            style.fill = { patternType: "solid", fgColor: { rgb: colors.lightRed }}
          } else if (headerName === "Prior") {
            style.fill = { patternType: "solid", fgColor: { rgb: colors.yellow }}
          } else if (headerName.includes("Var_Budget_")) {
            style.fill = { patternType: "solid", fgColor: { rgb: colors.lightOrange }}
          } else if (headerName.includes("Var_Prior_")) {
            style.fill = { patternType: "solid", fgColor: { rgb: colors.green }}
          }

          if (departmentHeaders[c].includes("%"))
            style.numFmt = "0%"

          ws[XLSX.utils.encode_cell({ r: currentRow + i, c })] =
            createCell(v, style)
        })

        // ---- BREAKOFF TABLE data rows ----
        breakoffHeaders.forEach((h, c) => {
          const value = row[h]
          let style = {}

          if (h.includes('%')) {
            style.numFmt = "0%"
          } else {
            style.numFmt = "$#,##0"
          }

          ws[XLSX.utils.encode_cell({ r: currentRow + i, c: startColForBreakoff + c })] =
            createCell(value, style)
        })
      })

      currentRow += departmentData.length
    }

    // =========================
    // finalize sheet
    // =========================
    const cells = Object.keys(ws).filter(key => !key.startsWith('!'))
    const coords = cells.map(c => XLSX.utils.decode_cell(c))

    ws["!ref"] = XLSX.utils.encode_range({
      s: { r: Math.min(...coords.map(x => x.r)), c: Math.min(...coords.map(x => x.c)) },
      e: { r: Math.max(...coords.map(x => x.r)), c: Math.max(...coords.map(x => x.c)) }
    })

    ws["!cols"] = Array(30).fill({ width: 15 })

    XLSX.utils.book_append_sheet(wb, ws, "Structured Report")

    const filename = `/tmp/structured_summary_pacing.xlsx`
    XLSX.writeFile(wb, filename)

    const stats = fs.statSync(filename)

    $.export("$summary",
      `Excel created: ${budgetData?.length || 0} budget rows, ${salesData?.length || 0} sales rows, ${departmentData?.length || 0} department rows`
    )

    return { filename, size: stats.size }
  }
})