# Growth Stocks API

*Archived Project - No longer in active development*

A Ruby on Rails API backend that provided real-time stock quote data with intelligent caching for a mobile stock tracking application. The API featured market-aware caching and iOS App Store subscription validation.

## Overview

This API served as the backend for a mobile app that tracked growth stocks with real-time quotes. It was designed to handle high-frequency requests efficiently while respecting API rate limits through sophisticated caching strategies.

### Key Features

- **Real-time Stock Quotes**: Integration with IEX Cloud API for live market data
- **Intelligent Caching**: Redis-based caching system that adapts to market hours
- **iOS Integration**: App Store receipt validation for subscription management
- **Market Awareness**: Automatic cache behavior adjustment based on trading hours

## Technical Architecture

### Core Technology Stack
- **Ruby on Rails 6.0** (API-only mode)
- **Redis** for intelligent caching
- **IEX Cloud API** for stock market data
- **Faraday** for HTTP client functionality

### API Endpoints
- `GET /api/:symbol/quotes` - Single stock quote
- `GET /api/quotes?symbols=AAPL,GOOGL` - Multiple stock quotes
- `GET /api/symbols` - Available stock symbols
- `POST /api/appstore/verify_receipt` - iOS subscription validation

### Smart Caching System
The application featured a sophisticated caching layer that automatically adjusted behavior based on market conditions:

- **Market Hours Awareness**: Different cache TTL during trading hours (4:30 AM - 8:00 PM ET)
- **Jittered Expiration**: Randomized cache expiration to prevent thundering herd problems
- **Automatic Cleanup**: Stale key detection and removal for optimal performance
- **Weekday Detection**: Cache behavior changes on weekends when markets are closed

### Service Architecture
- **InvestorsExchangeService**: IEX Cloud API integration
- **StocksCacheService**: Market-aware Redis caching logic
- **ReceiptService**: iOS App Store subscription validation
- **SymbolsService**: Stock symbol management

## iOS Client Application

This API was designed to work with a companion iOS application that provided the mobile interface for stock tracking. The iOS app handled user authentication, data visualization, and subscription management through this API.

**iOS Project**: [Growth Stocks](https://github.com/axelrivera/growth-stocks)

## Deployment
Originally deployed on Heroku with Redis Cloud for caching infrastructure. The application was designed to be stateless and horizontally scalable.

---

*This project has been archived and is no longer maintained. It serves as a demonstration of building scalable financial APIs with intelligent caching strategies.*
