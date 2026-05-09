# OrderFlow: Premium Offline Order Management System

OrderFlow is a 100% self-contained, offline-first Point of Sale (POS) and ledger application built using **Flutter** and **SQLite**. It is designed specifically for merchants transitioning from manual paper-and-pen ledger books to an elegant, high-performance desktop or tablet application.

---

## 🚀 Key Features

* **Offline-First & Local Persistence**: 100% independent of active internet connections, utilizing high-precision native SQLite drivers.
* **White-Label Branding**: Integrated stage setup wizard letting users customize store names, slogans, and visual symbols (e.g. Flam, Store, Food) dynamically.
* **Professional Analytics**: Dynamic sales widgets, top product listings, and real-time revenue counters displayed on a technical dark dashboard.
* **Inventory Control**: Easy creation, updating, and deletion of products catalog complete with support for custom dynamic tags/attributes.
* **Reactive Checkout (POS)**: Customer orders ledger featuring responsive item selections, real-time calculations, and safe transactional stock control.

---

## 📁 Repository Map & Documentation

This codebase utilizes strict Separation of Concerns. Detailed references are documented as follows:

* **[blueprint.md](file:///Users/michaeljosephsantos/Desktop/personal-projects/project-2/blueprint.md)**: **Single Source of Truth** for the entire codebase structure, database schemas, state models, and design systems.
* **[@GEMINI.md](file:///Users/michaeljosephsantos/Desktop/personal-projects/project-2/@GEMINI.md)**: AI agent rules and global developer coding protocols.
* **[/docs](file:///Users/michaeljosephsantos/Desktop/personal-projects/project-2/docs/)**: Additional technical details:
  * [docs/blueprint.md](file:///Users/michaeljosephsantos/Desktop/personal-projects/project-2/docs/blueprint.md) (Synchronized Codebase Map)
  * [docs/architecture.md](file:///Users/michaeljosephsantos/Desktop/personal-projects/project-2/docs/architecture.md) (High-level architectural structure)
  * [docs/database_schema.md](file:///Users/michaeljosephsantos/Desktop/personal-projects/project-2/docs/database_schema.md) (Detailed SQLite schema mappings)
  * [docs/setup_guide.md](file:///Users/michaeljosephsantos/Desktop/personal-projects/project-2/docs/setup_guide.md) (Development environment setup instructions)

---

## 🛠️ Development Setup

To run OrderFlow locally on your machine, follow these instructions:

1. **Clone the Repository**:
   ```bash
   git clone <repository-url>
   cd project-2
   ```

2. **Retrieve Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Launch the Application**:
   * For Web (Chrome):
     ```bash
     flutter run -d chrome
     ```
   * For Native Desktop (macOS):
     ```bash
     flutter run -d macos
     ```
