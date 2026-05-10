# Bulk CSV Product Ingestion & Column Rigidity Q&A

This document analyzes the technical requirements and architectural solutions for handling bulk product uploads via CSV within our dynamic SQLite/Flutter architecture.

---

## Technical Question

**The main problem of bulk product input using let's say CSV is they should follow specific columns, right?**

---

## 💡 Absolute Answer: YES

Yes, absolutely. By default, traditional CSV (Comma-Separated Values) ingestion pipelines rely on a **rigid structural contract** where the file headers must match the database table schema columns exactly. If the CSV columns are misaligned, missing, or mislabeled, the parser fails, causing SQL syntax crashes or corrupt null entries.

---

## Why is CSV Column Alignment a Complex Problem?

1. **Rigid Column Contracts**: 
   * A typical database parser expects standard headings like `name`, `unit_cost`, `selling_price`, and `quantity`. If a merchant uploads a CSV with columns labeled `Product Name`, `Buying Cost`, or `Retail Price`, standard parsers will break.
2. **The "Dynamic Column" Conflict**:
   * Our application uniquely allows merchants to define *custom product properties* (e.g., `'Weight'`, `'Size'`, `'Thread Count'`). In a static CSV, there is no native way to declare which columns represent standard inventory fields versus which represent custom, flexible parameters that should end up in our database's `extra_columns_json` column.
3. **Data Type and Parsing Exceptions**:
   * CSV stores everything as raw text. If currency symbols (like `₱` or `$`), trailing spaces, or empty fields are entered into columns expected to parse as floating-point numbers (`REAL`) or integers (`INTEGER`), standard insert scripts will fail.

---

## How Our Architecture Elegantly Solves This Rigidity

Rather than forcing the merchant into a strict, frustrating formatting corner, our system can utilize two premium design approaches to make CSV uploading completely seamless:

### Solution A: The Interactive Visual Column Mapper (Premium Approach)
Instead of throwing errors if the merchant's columns do not match our database, we build a **glassmorphic mapping wizard UI**. 
* **The Parser Steps**:
  1. The merchant uploads *any* CSV file.
  2. The application reads the first line (headers row) and lists all found CSV columns.
  3. The UI presents dropdown selectors, asking the merchant to map their columns to our core fields:
     * CSV Column for **Product Name** ➡️ maps to SQLite `name`
     * CSV Column for **Cost Price** ➡️ maps to SQLite `unit_cost`
     * CSV Column for **Selling Price** ➡️ maps to SQLite `selling_price`
     * CSV Column for **Initial Stock** ➡️ maps to SQLite `quantity`
  4. **The Magic Part**: Any remaining unmapped columns in their CSV (e.g., `'Color'`, `'Brand'`, `'Supplier'`) are **automatically harvested as custom dynamic properties** and serialized into our flexible `extra_columns_json` field!

#### How the Dynamic Mapping Code Works:
```dart
// Code example demonstrating how we dynamically map and ingest arbitrary CSV files
Map<String, dynamic> parseCsvRowToProductJson({
  required List<String> csvHeaders,
  required List<String> csvRowValues,
  required Map<String, String> userFieldMappings, // e.g. {"name": "Product Name", "selling_price": "Retail"}
}) {
  final Map<String, dynamic> productJson = {};
  final Map<String, String> extraColumns = {};

  for (int i = 0; i < csvHeaders.length; i++) {
    final String header = csvHeaders[i].trim();
    final String rawValue = csvRowValues[i].trim();

    // Check if this CSV header maps to a core system field
    if (header == userFieldMappings['name']) {
      productJson['name'] = rawValue;
    } else if (header == userFieldMappings['unit_cost']) {
      productJson['unit_cost'] = double.tryParse(rawValue.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
    } else if (header == userFieldMappings['selling_price']) {
      productJson['selling_price'] = double.tryParse(rawValue.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
    } else if (header == userFieldMappings['quantity']) {
      productJson['quantity'] = int.tryParse(rawValue) ?? 0;
    } else {
      // Unmapped columns are harvested automatically as custom flexible properties!
      if (rawValue.isNotEmpty) {
        extraColumns[header] = rawValue;
      }
    }
  }

  // Inject dynamic attributes into our schema contract
  productJson['extra_columns'] = extraColumns;
  return productJson;
}
```

### Solution B: Downloadable Standardized CSV Template (Robust Approach)
Alternatively, provide a beautiful **"Download Starter Template"** button within the App Onboarding products screen.
* The downloadable CSV contains structured columns:
  `Name, Unit Cost, Selling Price, Stock, Property:Size, Property:Weight, Property:Color`
* This template comes with explicit column prefix codes (like `Property:`) which our parser instantly recognizes to distinguish custom metadata from baseline inventory details.
