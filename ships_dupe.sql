import { axios } from "@pipedream/platform"
import xlsx from "xlsx"
import fs from "fs"

export default defineComponent({
  async run({steps, $}) {
    // Get the query results from the previous step
    const data = steps.detailed_file.$return_value
    
    // Create a new workbook and worksheet
    const wb = xlsx.utils.book_new()
    const ws = xlsx.utils.json_to_sheet(data)
    xlsx.utils.book_append_sheet(wb, ws, "Query Results")
    
    // Write to /tmp directory
    const filename = `/tmp/Daily Report ${steps.overview_metrics.$return_value[0].report_date}.xlsx`
    xlsx.writeFile(wb, filename)
    
    // Return the file path and basic stats
    const stats = fs.statSync(filename)
    return {
      filename,
      size: stats.size,
      rows: data.length,
      created: stats.birthtime
    }
  },
})