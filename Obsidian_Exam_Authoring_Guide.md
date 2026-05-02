# Obsidian Exam Authoring Guide

Welcome to the **Bitwise Academy Exam Content Engine**. We use Obsidian to quickly author, structure, and deploy rich mock exams to the app using Markdown.

This document details the expected structure and formatting guidelines for exams, enabling automatic parsing, uploading, and gamification setup in Firebase.

## 1. Directory Structure
Exams should be authored inside the `app/test_exams/` directory. Each exam is a single Markdown (`.md`) file. The parser processes all `.md` files in the given directory.

## 2. File Format

A valid exam markdown file consists of two parts:
1. **Frontmatter** (YAML metadata)
2. **Body** (The questions)

### 2.1 Frontmatter
The file **must** begin with a YAML frontmatter block containing metadata about the exam.

```yaml
---
title: "Quadratic Equations — Mid-Term Test"
subject: "Mathematics"
difficultyTier: "medium"
group: "MPSC Group B"
durationMinutes: 45
xpReward: 200
---
```

**Supported Fields:**
- `title` (String): The display name of the exam.
- `subject` (String): The topic. (e.g., Mathematics, Reasoning, English, History).
- `difficultyTier` (String): Use `easy`, `medium`, `hard`, or `ultra_hard`.
- `group` (String): The category/target exam. (e.g., "MPSC Group A", "SSC CGL", "Practice").
- `durationMinutes` (Number): Time limit in minutes.
- `xpReward` (Number): Experience points awarded on completion.

### 2.2 Writing Questions

Questions are written in the Markdown body. Each question begins with a standard Markdown heading (`#`, `##`, etc.).

#### Components of a Question:
- **Heading**: Used as a delimiter. E.g., `### Question 1` or `## Q2`. The text in the heading is ignored.
- **Question Text**: Text following the heading until the options. Supports rich markdown and LaTeX math (e.g., `$x^2 + y^2$`).
- **Options**: Defined as an unordered list using dashes `-`. You can provide 2 to 5 options.
- **Answer**: Highlighted by placing `**Answer:**` immediately followed by the exact text of the correct option.
- **Explanation** *(Optional)*: Highlighted by placing `**Explanation:**` followed by the detailed reasoning.
- **Tags/Metadata** *(Optional)*: Highlighted by placing `**Tags:**` followed by comma-separated words.

#### Example Question
```markdown
## Question 1
Find the roots of the quadratic equation: $2x^2 - 5x + 3 = 0$

- $1, 1.5$
- $-1, -1.5$
- $2, 3$
- $1, 3$

**Answer:** $1, 1.5$

**Explanation:**
Using the quadratic formula:
$x = \frac{-(-5) \pm \sqrt{(-5)^2 - 4(2)(3)}}{2(2)}$
$x = \frac{5 \pm \sqrt{25 - 24}}{4}$
$x = \frac{5 \pm 1}{4}$
So, $x = 1.5$ or $x = 1$.

**Tags:** roots, quadratic-formula
```

## 3. How to Upload

Once you have authored your markdown files in `app/test_exams/`, open a terminal and run the following commands:

### Step 1: Parse the Markdown into JSON
Converts the `.md` files into a unified `database_seed.json`.

```bash
cd app
dart scripts/obsidian_parser.dart test_exams database_seed.json
```

### Step 2: Upload to Firestore
Reads the JSON file and pushes the exam and question documents directly to Firebase, while automatically updating global metadata settings in the app.

```bash
cd app
dart scripts/upload_to_firestore.dart
```

---
**Tips:**
- Make sure your Firebase Emulator or Production environment is correctly set up in your `service-account.json`.
- The `Answer:` exact match is case-sensitive and must identically match the chosen option's markdown.
- All parsed topics and difficulties are collected dynamically and presented in the user's Mock Test Configuration screen.
