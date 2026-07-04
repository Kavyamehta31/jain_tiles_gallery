# ANTIGRAVITY.md

# Jain Tiles Gallery

This file defines the permanent engineering rules for this repository.

These instructions apply to every task unless explicitly overridden.

---

# Project Overview

Project Name:

Jain Tiles Gallery

Purpose:

A production-quality offline Android inventory management application for a tile showroom.

This application is intended for daily production use.

Everything must be implemented with production-quality standards.

---

# Technology Stack

Flutter

Material 3

SQLite (sqflite)

path_provider

image_picker

uuid

intl

No Firebase

No Cloud

No Authentication

No Internet dependency

No Hive

No GetX

No Provider

No Riverpod

No Bloc

Everything must function completely offline.

---

# Architecture

Always preserve this structure.

lib/

constants/

database/

models/

services/

utils/

widgets/

screens/

splash/

main/

home/

products/

transactions/

reports/

settings/

Never reorganize the project unless absolutely necessary.

---

# Development Rules

Always analyze the existing project before making modifications.

Read every dependent file before changing code.

Understand the architecture before implementing new features.

Never generate incomplete implementations.

Never generate placeholder implementations.

Never generate TODO comments.

Never omit imports.

Never omit methods.

Never intentionally leave compile errors.

Whenever a file changes, rewrite the complete file.

Never ask the user to manually finish code.

---

# Engineering Principles

Follow SOLID principles.

Prefer composition over duplication.

Keep widgets reusable.

Keep business logic inside services.

Keep UI inside screens/widgets.

Keep database logic inside services/database.

Use meaningful naming.

Avoid magic numbers.

Reuse constants.

Avoid duplicated code.

---

# Database Rules

SQLite only.

Database must remain normalized.

Products

↓

Product Images

↓

Transactions

Never serialize image lists into a database column.

Use foreign keys.

Enable

PRAGMA foreign_keys = ON

Always use SQLite transactions for write operations.

Always use asynchronous database operations.

Handle database exceptions properly.

---

# Image Storage Rules

Images are selected from gallery.

Images must be copied into application storage.

Store only local file paths.

Never rely on gallery paths.

Delete physical images when products are deleted.

Delete unused images when products are edited.

One product can have multiple images.

The first image acts as the thumbnail.

---

# UI Guidelines

Material 3

Professional appearance

Minimal design

White background

Bronze / Gold accent

Rounded cards

Rounded text fields

Consistent spacing

Responsive layout

Professional typography

No placeholder UI.

---

# Code Quality

Every implementation must compile.

Avoid deprecated APIs.

Avoid warnings.

Avoid unused imports.

Avoid dead code.

Avoid duplicated widgets.

Use reusable components whenever possible.

---

# Verification Workflow

After every feature:

Run

flutter analyze

Fix every issue.

Run again until zero issues remain.

If widget tests exist:

Run

flutter test

Fix failures automatically.

Never stop after the first error.

Continue until the project builds successfully.

---

# Git Workflow

After completing a feature:

Suggest a meaningful commit message.

Example:

feat(products): complete offline products module

feat(transactions): implement stock movement

feat(reports): implement reporting module

feat(settings): implement settings module

---

# Current Project Status

Completed:

Products Module

Includes:

SQLite integration

Product CRUD

Multiple image support

Image sandboxing

Dynamic variety dropdown

Material 3 UI

Search

Edit

Delete

Validation

Do not rewrite completed modules unless fixing bugs.

Reuse existing implementation.

---

# Working Style

Implement complete features.

Do not stop after every file.

Continue until the entire feature is complete.

Only stop when:

The module is complete

flutter analyze returns zero issues

Tests pass (if applicable)

No further engineering work remains for that module.

---

# Communication Style

Keep responses concise.

Do not explain basic Flutter concepts.

Do not provide unnecessary theory.

Focus on implementation.

Only ask questions if a business requirement is genuinely ambiguous.

Otherwise make reasonable engineering decisions.

---

# Goal

Build a polished production-ready offline Flutter application suitable for daily use in a real tile showroom.

Prioritize:

Correctness

Maintainability

Scalability

Reliability

Consistency

Code quality over speed.
