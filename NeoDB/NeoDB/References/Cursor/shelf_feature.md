# Shelf Feature Implementation

## Overview
Adding shelf display functionality to ProfileView to show user's collection of items.

## API Endpoints
- GET `/api/me/shelf/{type}`
  - Types: wishlist, progress, complete, dropped
  - Optional query params: category, page
  - Returns: PagedMarkSchema

## Models to Add
1. ShelfType enum
2. Mark model
3. PagedMark model

## Implementation Plan
1. Create ShelfService for API calls
2. Add shelf section to ProfileView
3. Add ShelfItemView for individual items
4. Implement pagination

## Changes
- Added ShelfService.swift for API communication
- Updated ProfileViewModel to handle shelf data
- Added shelf section to ProfileView UI
- Added models for shelf data structures 