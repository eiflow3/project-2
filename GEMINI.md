# Gemini Developer Instructions & Repository Rules

Welcome, Gemini. This document outlines the absolute behavioral protocols and design standards required when pair-programming or making modifications in this repository.

---

## 🚨 CRITICAL RULE: Consult the Codebase Blueprint FIRST

Whenever the user asks for a feature, code change, styling modification, or bug fix:
* **You MUST ALWAYS refer to [blueprint.md](file:///Users/michaeljosephsantos/Desktop/personal-projects/project-2/blueprint.md) first.**
* Do **NOT** blindly search or scour the entire codebase. 
* Use the Blueprint to identify the correct layer (Presentation, Providers, Data models, Repositories, or Database Service) and the target files involved.
* This ensures that any and all changes match the architecture and folder standards of the project.

---

## 🛠️ Global Developer Rules (Mandatory)

You must follow these rules without exception on every single task:

### 1. Questions & Answers Documenting
* When the user asks technical questions, after answering them, you must document the Q&A inside the `/questions` folder.
* **Avoid duplication**: Check if a Q&A document for the topic already exists.
* If a Q&A already exists, inform the user: *"There is already a Q&A for this question. Would you like to update it or not?"*

### 2. Documentation Syncing
* When modifying any file in the workspace, you **MUST** also update its corresponding reference documentation inside the `/docs` folder to keep everything in sync (including `docs/blueprint.md` if structure or interfaces are altered).

### 3. Modular Code Split
* Do **NOT** dump code into single massive files. 
* Strictly split components, pages, widgets, models, repositories, and state controllers into separate, specialized files under their respective paths.

### 4. Package Installation via UV
* Use `uv add <package>` for any additional packages to avoid polluting global environments.

### 5. Inline Commenting & Readability
* When writing or updating scripts/code files, you **MUST** add clear inline comments explaining how the code works. This maximizes readability and reduces cognitive effort for any developer onboarding to the codebase.

---

## 🎨 Visual Aesthetics & High-Quality Design Protocol

Since this application targets a premium merchant desk-experience, any visual assets, screens, widgets, or themes you modify must adhere to:
* **Slate/Teal Theme Harmony**: Only use color tokens defined in [colors.dart](file:///Users/michaeljosephsantos/Desktop/personal-projects/project-2/lib/core/theme/colors.dart). Do not invent ad-hoc colors.
* **Modern Minimalist Layout Division**: Strictly use thin borders (`1.0px` Slate-border outlines) and flat, sharp drop-shadows as defined in [style.dart](file:///Users/michaeljosephsantos/Desktop/personal-projects/project-2/lib/core/theme/style.dart).
* **Precise Corner Radii**: Do not use bubbly interfaces. Use the professional Swiss micro-radii tokens (`4.0`, `6.0`, `8.0` pixels).
* **No Placeholders**: Never leave mock descriptions or images. Use real functional lists or real DB integrations. If graphic assets are needed, generate them using proper tools or code-drawing.


# Github
## Avoid atomic commits on every changes unless requested by the user.