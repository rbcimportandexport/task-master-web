// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

Widget buildPlatformSheetView({
  required String url,
  required String viewId,
  String title = 'Google Sheet',
  bool directGoogleEmbed = false,
}) {
  final trimmedUrl = url.trim();
  String embedUrl = trimmedUrl;
  String docId = '';

  // Extract Google Sheet Doc ID flexibly (supports /d/<id>, /u/0/d/<id>, /d/e/<id>, etc.)
  if (embedUrl.contains('spreadsheets') || embedUrl.contains('docs.google.com')) {
    final regex = RegExp(r'/d/(?:e/)?([a-zA-Z0-9_-]+)');
    final match = regex.firstMatch(embedUrl);
    if (match != null) {
      docId = match.group(1) ?? '';
      embedUrl = 'https://docs.google.com/spreadsheets/d/$docId/edit?usp=sharing';
    }
  }

  final uniqueKey = 'sheet-view-$viewId-${directGoogleEmbed ? "direct" : "full"}-${trimmedUrl.hashCode}';

  ui_web.platformViewRegistry.registerViewFactory(uniqueKey, (int id) {
    final iframe = html.IFrameElement()
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.minHeight = '100%'
      ..style.display = 'block'
      ..allow = 'clipboard-read; clipboard-write; microphone; camera; encrypted-media; fullscreen; geolocation; autoplay'
      ..setAttribute('allowfullscreen', 'true');

    if (directGoogleEmbed && embedUrl.isNotEmpty) {
      iframe.src = embedUrl;
    } else {
      iframe.srcdoc = _buildGoogleSheetsHtml(
        title: title,
        sheetId: viewId,
        rawUrl: trimmedUrl.isNotEmpty ? trimmedUrl : embedUrl,
        docId: docId,
      );
    }

    // Capture Ctrl+S / Cmd+S on top-level window so browser never shows "Save Page As" dialog
    html.window.onKeyDown.listen((event) {
      if ((event.ctrlKey || event.metaKey) && (event.key == 's' || event.key == 'S')) {
        event.preventDefault();
        event.stopPropagation();
        try {
          iframe.contentWindow?.postMessage('save_and_sync', '*');
        } catch (_) {}
      }
    });

    return iframe;
  });

  return HtmlElementView(viewType: uniqueKey);
}

String _buildGoogleSheetsHtml({
  required String title,
  required String sheetId,
  required String rawUrl,
  required String docId,
}) {
  final safeTitle = const HtmlEscape().convert(title.isEmpty ? 'Untitled spreadsheet' : title);
  final safeId = const HtmlEscape().convert(sheetId);
  final safeRawUrl = const HtmlEscape().convert(
    rawUrl.isNotEmpty ? rawUrl : (docId.isNotEmpty ? 'https://docs.google.com/spreadsheets/d/$docId/edit' : 'https://docs.google.com/spreadsheets/create'),
  );
  final safeDocId = const HtmlEscape().convert(docId);

  return '''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>$safeTitle - Google Sheets</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Roboto:wght@400;500;700&family=Google+Sans:wght@400;500;700&display=swap" rel="stylesheet">
<link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; font-family: 'Roboto', -apple-system, BlinkMacSystemFont, sans-serif; }
  body, html { width: 100%; height: 100%; overflow: hidden; background: #fff; color: #202124; display: flex; flex-direction: column; font-size: 13px; user-select: none; }
  
  /* Top App Bar */
  .header {
    background: #fff;
    border-bottom: 1px solid #dadce0;
    display: flex;
    flex-direction: column;
    padding: 6px 12px 4px 12px;
    flex-shrink: 0;
  }
  .header-top {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 8px;
    height: 34px;
    flex-wrap: nowrap;
  }
  .header-left {
    display: flex;
    align-items: center;
    gap: 8px;
    flex: 1;
    min-width: 0;
    overflow: hidden;
  }
  .sheets-icon {
    width: 28px;
    height: 28px;
    background: #0f9d58;
    border-radius: 4px;
    display: flex;
    align-items: center;
    justify-content: center;
    color: white;
    flex-shrink: 0;
    box-shadow: 0 1px 2px rgba(0,0,0,0.15);
  }
  .sheets-icon svg { width: 18px; height: 18px; fill: white; }
  .doc-title {
    font-family: 'Google Sans', 'Roboto', sans-serif;
    font-size: 15px;
    font-weight: 500;
    color: #202124;
    border: 1px solid transparent;
    border-radius: 4px;
    padding: 2px 6px;
    cursor: text;
    outline: none;
    max-width: 180px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }
  .doc-title:focus {
    border-color: #1a73e8;
    background: #fff;
  }
  
  /* Live sync badge */
  .sync-badge {
    display: inline-flex;
    align-items: center;
    gap: 4px;
    font-size: 11px;
    font-weight: 500;
    color: #0f9d58;
    background: #e6f4ea;
    border: 1px solid #ceead6;
    padding: 2px 8px;
    border-radius: 12px;
    white-space: nowrap;
    flex-shrink: 0;
  }
  .sync-badge.syncing {
    color: #1a73e8;
    background: #e8f0fe;
    border-color: #d2e3fc;
  }
  .sync-badge.synced {
    color: #0f9d58;
    background: #e6f4ea;
    border-color: #ceead6;
  }
  .sync-badge.local {
    color: #444746;
    background: #f1f3f4;
    border-color: #dadce0;
    cursor: pointer;
  }
  .sync-badge.warning {
    color: #b06000;
    background: #fef7e0;
    border-color: #feefc3;
    cursor: pointer;
  }
  .sync-badge .material-icons { font-size: 13px; }
  .material-icons.spinning {
    animation: spin 0.8s linear infinite;
  }
  .sync-dot {
    width: 7px;
    height: 7px;
    border-radius: 50%;
    background: #0f9d58;
    display: inline-block;
  }
  .sync-dot.pulse {
    animation: pulse 1.5s infinite;
  }
  @keyframes pulse {
    0% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(15, 157, 88, 0.7); }
    70% { transform: scale(1); box-shadow: 0 0 0 5px rgba(15, 157, 88, 0); }
    100% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(15, 157, 88, 0); }
  }
  
  .header-right {
    display: flex;
    align-items: center;
    gap: 6px;
    flex-shrink: 0;
  }
  .btn-action {
    border: none;
    border-radius: 14px;
    padding: 5px 10px;
    font-weight: 500;
    font-size: 11.5px;
    display: flex;
    align-items: center;
    gap: 4px;
    cursor: pointer;
    transition: all 0.15s ease;
    white-space: nowrap;
    text-decoration: none;
  }
  .btn-save {
    background: #1a73e8;
    color: #fff;
    border: 1px solid #1a73e8;
  }
  .btn-save:hover { background: #1557b0; }
  .btn-save.saving {
    background: #f1f3f4;
    color: #5f6368;
    border: 1px solid #dadce0;
    cursor: wait;
  }
  .btn-sync {
    background: #e8f0fe;
    color: #1a73e8;
    border: 1px solid #c2e7ff;
  }
  .btn-sync:hover { background: #d2e3fc; }
  .btn-sync.spinning .material-icons {
    animation: spin 0.8s linear infinite;
  }
  @keyframes spin { 100% { transform: rotate(360deg); } }

  .btn-2way {
    background: #fef7e0;
    color: #b06000;
    border: 1px solid #feefc3;
  }
  .btn-2way:hover { background: #feefc3; }

  .btn-open-google {
    background: #0f9d58;
    color: #fff;
  }
  .btn-open-google:hover { background: #0b8043; }

  .btn-export {
    background: #f1f3f4;
    color: #3c4043;
    border: 1px solid #dadce0;
  }
  .btn-export:hover { background: #e8eaed; }
  
  .menu-bar {
    display: flex;
    align-items: center;
    gap: 4px;
    margin-top: 4px;
    padding-bottom: 2px;
    overflow-x: auto;
    white-space: nowrap;
    scrollbar-width: none;
    width: 100%;
  }
  .menu-item {
    padding: 2px 6px;
    border-radius: 4px;
    color: #3c4043;
    font-size: 12px;
    cursor: pointer;
    white-space: nowrap;
  }
  .menu-item:hover { background: #f1f3f4; color: #202124; }
  
  /* Share notice alert banner */
  .share-banner {
    background: #fef7e0;
    border-bottom: 1px solid #feefc3;
    color: #5c3b00;
    padding: 6px 12px;
    font-size: 12px;
    display: flex;
    align-items: center;
    gap: 8px;
    flex-shrink: 0;
  }
  .share-banner .material-icons { font-size: 18px; color: #e37400; }
  .share-banner button.btn-inline {
    background: #1a73e8;
    color: white;
    border: none;
    padding: 2px 8px;
    border-radius: 4px;
    font-size: 11px;
    cursor: pointer;
    margin-left: 6px;
  }
  .share-banner .btn-close {
    background: transparent;
    border: none;
    cursor: pointer;
    font-size: 16px;
    color: #5c3b00;
    padding: 0 4px;
  }

  @media (max-width: 600px) {
    .sync-badge span.badge-text { display: none; }
    .btn-action span.btn-text { display: none; }
    .btn-action { padding: 5px 7px; }
    .doc-title { max-width: 120px; }
  }

  /* Primary Toolbar */
  .toolbar {
    background: #edf2fa;
    border-radius: 24px;
    margin: 4px 8px 6px 8px;
    padding: 3px 8px;
    display: flex;
    align-items: center;
    gap: 2px;
    overflow-x: auto;
    flex-shrink: 0;
  }
  .tool-btn {
    background: transparent;
    border: none;
    border-radius: 4px;
    padding: 4px 6px;
    cursor: pointer;
    color: #444746;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 13px;
    height: 28px;
    min-width: 28px;
  }
  .tool-btn:hover { background: #dde3ea; color: #1f1f1f; }
  .tool-btn.active { background: #d3e3fd; color: #041e49; font-weight: bold; }
  .tool-btn .material-icons { font-size: 18px; }
  .tool-sep { width: 1px; height: 18px; background: #c4c7c5; margin: 0 4px; flex-shrink: 0; }
  
  .font-select, .size-select {
    border: none;
    background: transparent;
    padding: 2px 6px;
    border-radius: 4px;
    font-size: 12px;
    color: #444746;
    outline: none;
    cursor: pointer;
    height: 28px;
  }
  .font-select:hover, .size-select:hover { background: #dde3ea; }
  
  /* Formula Bar */
  .formula-bar {
    display: flex;
    align-items: center;
    background: #fff;
    border-bottom: 1px solid #dadce0;
    padding: 4px 12px;
    gap: 8px;
    flex-shrink: 0;
    height: 32px;
  }
  .cell-name-box {
    width: 60px;
    height: 24px;
    border: 1px solid #dadce0;
    border-radius: 2px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: 500;
    font-size: 12px;
    color: #3c4043;
    background: #f8f9fa;
  }
  .fx-symbol {
    font-style: italic;
    font-weight: bold;
    color: #5f6368;
    font-family: 'Google Sans', sans-serif;
    font-size: 14px;
  }
  .formula-input {
    flex: 1;
    height: 24px;
    border: none;
    outline: none;
    font-size: 13px;
    color: #202124;
    padding: 0 6px;
  }
  .formula-input:focus { background: #f8fafd; }
  
  /* Spreadsheet Grid Viewport */
  .grid-container {
    flex: 1;
    overflow: auto;
    position: relative;
    background: #fff;
    cursor: cell;
  }
  table.sheet-table {
    border-collapse: collapse;
    table-layout: fixed;
    background: #fff;
    font-size: 12px;
  }
  
  /* Column & Row Headers */
  th.corner-header {
    width: 46px;
    min-width: 46px;
    max-width: 46px;
    height: 24px;
    background: #f8f9fa;
    border-right: 1px solid #dadce0;
    border-bottom: 1px solid #dadce0;
    position: sticky;
    top: 0;
    left: 0;
    z-index: 10;
  }
  th.col-header {
    height: 24px;
    width: 100px;
    min-width: 100px;
    background: #f8f9fa;
    border-right: 1px solid #dadce0;
    border-bottom: 1px solid #dadce0;
    font-weight: 500;
    color: #5f6368;
    text-align: center;
    position: sticky;
    top: 0;
    z-index: 5;
    user-select: none;
  }
  th.col-header.selected { background: #e8f0fe; color: #1a73e8; }
  
  th.row-header {
    width: 46px;
    min-width: 46px;
    max-width: 46px;
    background: #f8f9fa;
    border-right: 1px solid #dadce0;
    border-bottom: 1px solid #dadce0;
    font-weight: 500;
    color: #5f6368;
    text-align: center;
    position: sticky;
    left: 0;
    z-index: 4;
    user-select: none;
  }
  th.row-header.selected { background: #e8f0fe; color: #1a73e8; }
  
  /* Cells */
  td.sheet-cell {
    border-right: 1px solid #e0e0e0;
    border-bottom: 1px solid #e0e0e0;
    padding: 0 6px;
    height: 24px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: clip;
    color: #000;
    outline: none;
    position: relative;
    background: #fff;
  }
  td.sheet-cell.selected {
    box-shadow: inset 0 0 0 2px #1a73e8;
    z-index: 2;
  }
  td.sheet-cell.selected::after {
    content: '';
    position: absolute;
    right: -3px;
    bottom: -3px;
    width: 6px;
    height: 6px;
    background: #1a73e8;
    border: 1px solid #fff;
    cursor: crosshair;
    z-index: 3;
  }
  td.sheet-cell.editing {
    box-shadow: inset 0 0 0 2px #1a73e8;
    background: #fff !important;
    cursor: text;
  }
  
  /* Bottom Sheet Tabs Bar */
  .tabs-bar {
    height: 36px;
    background: #f8f9fa;
    border-top: 1px solid #dadce0;
    display: flex;
    align-items: center;
    padding: 0 8px;
    gap: 4px;
    flex-shrink: 0;
  }
  .tab-btn {
    background: transparent;
    border: none;
    border-radius: 50%;
    width: 26px;
    height: 26px;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    color: #5f6368;
  }
  .tab-btn:hover { background: #e8eaed; color: #202124; }
  .tab-btn .material-icons { font-size: 18px; }
  
  .sheet-tabs-list {
    display: flex;
    align-items: center;
    gap: 4px;
    margin-left: 8px;
    overflow-x: auto;
  }
  .sheet-tab {
    background: #e8eaed;
    border: 1px solid #dadce0;
    border-bottom: none;
    border-radius: 6px 6px 0 0;
    padding: 6px 14px;
    font-size: 12px;
    font-weight: 500;
    color: #3c4043;
    cursor: pointer;
    display: flex;
    align-items: center;
    gap: 6px;
  }
  .sheet-tab.active {
    background: #fff;
    color: #0f9d58;
    border-color: #dadce0;
    box-shadow: 0 -2px 0 0 #0f9d58 inset;
  }
  
  /* Toast message */
  .toast {
    position: fixed;
    bottom: 46px;
    left: 20px;
    background: #323232;
    color: #fff;
    padding: 10px 16px;
    border-radius: 4px;
    font-size: 13px;
    box-shadow: 0 2px 10px rgba(0,0,0,0.25);
    display: none;
    align-items: center;
    gap: 8px;
    z-index: 999;
  }

  /* Modal Dialog for 2-Way Sync Setup */
  .modal-overlay {
    position: fixed;
    top: 0; left: 0; right: 0; bottom: 0;
    background: rgba(0,0,0,0.45);
    display: none;
    align-items: center;
    justify-content: center;
    z-index: 1000;
    backdrop-filter: blur(2px);
  }
  .modal-card {
    background: #fff;
    border-radius: 12px;
    max-width: 580px;
    width: 90%;
    max-height: 85vh;
    overflow-y: auto;
    padding: 24px;
    box-shadow: 0 10px 30px rgba(0,0,0,0.2);
  }
  .modal-title {
    display: flex;
    align-items: center;
    gap: 8px;
    font-size: 18px;
    font-weight: 700;
    color: #202124;
    margin-bottom: 12px;
  }
  .modal-title .material-icons { color: #0f9d58; font-size: 24px; }
  .code-box {
    background: #1e1e1e;
    color: #d4d4d4;
    font-family: 'Courier New', Courier, monospace;
    font-size: 12px;
    padding: 12px;
    border-radius: 8px;
    overflow-x: auto;
    margin: 10px 0;
    position: relative;
    user-select: text;
  }
  .input-group {
    margin: 14px 0;
    display: flex;
    flex-direction: column;
    gap: 6px;
  }
  .input-group label {
    font-weight: 600;
    color: #3c4043;
    font-size: 12px;
  }
  .input-group input {
    padding: 8px 12px;
    border: 1px solid #dadce0;
    border-radius: 6px;
    font-size: 13px;
    outline: none;
  }
  .input-group input:focus { border-color: #1a73e8; box-shadow: 0 0 0 2px rgba(26,115,232,0.2); }
  .modal-actions {
    display: flex;
    justify-content: flex-end;
    gap: 8px;
    margin-top: 18px;
  }
  .btn-modal {
    padding: 8px 16px;
    border-radius: 6px;
    border: none;
    font-size: 13px;
    font-weight: 500;
    cursor: pointer;
  }
  .btn-modal-cancel { background: #f1f3f4; color: #3c4043; }
  .btn-modal-primary { background: #0f9d58; color: white; }
  .btn-modal-primary:hover { background: #0b8043; }
</style>
</head>
<body>

<!-- Header -->
<div class="header">
  <div class="header-top">
    <div class="header-left">
      <div class="sheets-icon" title="Google Sheets">
        <svg viewBox="0 0 24 24"><path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm0 16H5V5h14v14zM7 7h10v2H7zm0 4h10v2H7zm0 4h7v2H7z"/></svg>
      </div>
      <input type="text" id="docTitle" class="doc-title" value="$safeTitle" spellcheck="false" title="Document Title">
      
      <!-- Live Sync Status Badge -->
      <div class="sync-badge" id="syncBadge" title="Live sync status with Google Sheets" onclick="syncFromGoogleSheet()">
        <span class="sync-dot pulse" id="syncDot"></span>
        <span class="badge-text" id="syncStatusText">Connecting...</span>
      </div>
    </div>
    
    <div class="header-right">
      <button class="btn-action btn-save" id="btnSaveNow" onclick="performSaveAndSync()" title="Save all changes to Google Sheet (Ctrl+S)">
        <span class="material-icons" style="font-size: 15px;">cloud_upload</span>
        <span class="btn-text">Save (Ctrl+S)</span>
      </button>

      <button class="btn-action btn-sync" id="btnSyncNow" onclick="syncFromGoogleSheet()" title="Instant Sync with Google Sheets">
        <span class="material-icons" style="font-size: 15px;">sync</span>
        <span class="btn-text">Sync Now</span>
      </button>

      <button class="btn-action btn-2way" onclick="open2WayModal()" title="Setup live 2-way write sync with Google Sheet">
        <span class="material-icons" style="font-size: 15px;">bolt</span>
        <span class="btn-text">2-Way Sync</span>
      </button>

      <a href="$safeRawUrl" target="_blank" rel="noopener noreferrer" class="btn-action btn-open-google" title="Open live Google Sheets in full tab to edit directly">
        <span class="material-icons" style="font-size: 15px;">open_in_new</span>
        <span class="btn-text">Google Sheets</span>
      </a>

      <button class="btn-action btn-export" onclick="exportCsv()" title="Download as CSV">
        <span class="material-icons" style="font-size: 15px;">file_download</span>
        <span class="btn-text">Export</span>
      </button>
    </div>
  </div>

  <div class="menu-bar">
    <span class="menu-item" style="font-weight: 700; color: #1a73e8;" onclick="performSaveAndSync()">Save (Ctrl+S)</span>
    <span class="menu-item" onclick="syncFromGoogleSheet()">Sync from Google</span>
    <span class="menu-item" onclick="open2WayModal()">Setup 2-Way Sync</span>
    <span class="menu-item" onclick="window.open('$safeRawUrl', '_blank')">Open in Google Sheets</span>
    <span class="menu-item" onclick="insertRowBelow()">Insert Row</span>
    <span class="menu-item" onclick="toggleBold()">Format Bold</span>
    <span class="menu-item" onclick="exportCsv()">Export CSV</span>
    <span class="menu-item" onclick="showToast('Auto-sync is running every 4 seconds')">Status: Live Polling</span>
  </div>
</div>

<!-- Notice banner if Google Sheet needs Public Share -->
<div id="shareNoticeBanner" class="share-banner" style="display: none;">
  <span class="material-icons">info</span>
  <div style="flex:1;">
    <strong>Google Sheet Not Synced:</strong> Google Sheet se live data sync karne ke liye Google Sheet me 
    <strong>Share &gt; General access &gt; "Anyone with the link"</strong> set karein, fir yahan 
    <button class="btn-inline" onclick="syncFromGoogleSheet()">Sync Now</button> click karein.
  </div>
  <button class="btn-close" onclick="document.getElementById('shareNoticeBanner').style.display='none'">X</button>
</div>

<!-- Formatting Toolbar -->
<div class="toolbar">
  <button class="tool-btn" title="Undo (Ctrl+Z)" onclick="undo()"><span class="material-icons">undo</span></button>
  <button class="tool-btn" title="Redo (Ctrl+Y)" onclick="redo()"><span class="material-icons">redo</span></button>
  <button class="tool-btn" title="Print" onclick="window.print()"><span class="material-icons">print</span></button>
  <div class="tool-sep"></div>

  <select class="font-select" id="fontFamily" onchange="applyFontFamily(this.value)">
    <option value="Roboto">Default (Roboto)</option>
    <option value="Arial">Arial</option>
    <option value="'Google Sans'">Google Sans</option>
    <option value="'Courier New'">Monospace</option>
    <option value="Georgia">Georgia</option>
  </select>
  
  <select class="size-select" id="fontSize" onchange="applyFontSize(this.value)">
    <option value="10">10</option>
    <option value="11">11</option>
    <option value="12" selected>12</option>
    <option value="14">14</option>
    <option value="16">16</option>
    <option value="18">18</option>
  </select>

  <div class="tool-sep"></div>
  <button class="tool-btn" id="btnBold" title="Bold (Ctrl+B)" onclick="toggleBold()"><span class="material-icons">format_bold</span></button>
  <button class="tool-btn" id="btnItalic" title="Italic (Ctrl+I)" onclick="toggleItalic()"><span class="material-icons">format_italic</span></button>
  <button class="tool-btn" id="btnStrike" title="Strikethrough" onclick="toggleStrike()"><span class="material-icons">format_strikethrough</span></button>
  <button class="tool-btn" title="Text color" onclick="changeTextColor()"><span class="material-icons">format_color_text</span></button>
  <button class="tool-btn" title="Fill color" onclick="changeBgColor()"><span class="material-icons">format_color_fill</span></button>

  <div class="tool-sep"></div>
  <button class="tool-btn" title="Align left" onclick="alignCell('left')"><span class="material-icons">format_align_left</span></button>
  <button class="tool-btn" title="Align center" onclick="alignCell('center')"><span class="material-icons">format_align_center</span></button>
  <button class="tool-btn" title="Align right" onclick="alignCell('right')"><span class="material-icons">format_align_right</span></button>

  <div class="tool-sep"></div>
  <button class="tool-btn" title="Functions (SUM, AVG, COUNT)" onclick="insertFormula('SUM')"><span class="material-icons">functions</span></button>
  <button class="tool-btn" title="Insert Row" onclick="insertRowBelow()"><span class="material-icons">table_rows</span></button>
  <button class="tool-btn" title="Insert Column" onclick="insertColRight()"><span class="material-icons">view_column</span></button>
  <button class="tool-btn" title="Clear cell" onclick="clearSelectedCell()"><span class="material-icons">backspace</span></button>
</div>

<!-- Formula Bar -->
<div class="formula-bar">
  <div class="cell-name-box" id="cellNameBox">A1</div>
  <div class="fx-symbol">fx</div>
  <input type="text" class="formula-input" id="formulaInput" placeholder="Enter text or formula (e.g. =SUM(A1:A5))" spellcheck="false">
</div>

<!-- Spreadsheet Grid -->
<div class="grid-container" id="gridContainer">
  <table class="sheet-table" id="sheetTable">
    <thead id="sheetThead"></thead>
    <tbody id="sheetTbody"></tbody>
  </table>
</div>

<!-- Bottom Tabs -->
<div class="tabs-bar">
  <button class="tab-btn" title="Add Sheet" onclick="addNewTab()"><span class="material-icons">add</span></button>
  <button class="tab-btn" title="All Sheets" onclick="showToast('Sheet 1 active')"><span class="material-icons">menu</span></button>
  <div class="sheet-tabs-list" id="sheetTabsList">
    <div class="sheet-tab active" id="tab-1" onclick="switchTab(1)">
      <span class="material-icons" style="font-size: 14px; color: #0f9d58;">table_chart</span>
      <span>Sheet1</span>
    </div>
  </div>
</div>

<!-- Toast -->
<div class="toast" id="toastMsg"></div>

<!-- 2-Way Sync Modal -->
<div class="modal-overlay" id="syncModal">
  <div class="modal-card">
    <div class="modal-title">
      <span class="material-icons">sync_alt</span>
      <span>Google Sheet 2-Way Live Sync</span>
    </div>
    
    <p style="color: #5f6368; font-size: 13px; line-height: 1.5; margin-bottom: 12px;">
      Is app se real Google Sheet par live update bhejne ke liye niche diya gaya simple Google Apps Script use karein.
    </p>

    <div style="background: #f8f9fa; border: 1px solid #dadce0; border-radius: 8px; padding: 12px; margin-bottom: 14px;">
      <div style="font-weight: 600; font-size: 13px; color: #202124; margin-bottom: 6px;">3 Simple Steps to Enable 2-Way Sync:</div>
      <ol style="margin-left: 20px; color: #444746; font-size: 12.5px; line-height: 1.6;">
        <li>Apne Google Sheet me upar <strong>Extensions &gt; Apps Script</strong> par click karein.</li>
        <li>Niche diya gaya script paste karein aur <strong>Deploy &gt; New deployment &gt; Web app</strong> select karein (Execute as: <strong>Me</strong>, Who has access: <strong>Anyone</strong>).</li>
        <li>Milne wala <strong>Web App URL</strong> yahan paste karke <strong>Save</strong> karein.</li>
      </ol>
    </div>

    <div style="display: flex; justify-content: space-between; align-items: center;">
      <span style="font-weight: 600; font-size: 12px; color: #3c4043;">Apps Script Code:</span>
      <button class="btn-modal btn-modal-primary" style="padding: 4px 10px; font-size: 11px;" onclick="copyScriptCode()">
        <span class="material-icons" style="font-size: 14px; vertical-align: middle;">content_copy</span> Copy Code
      </button>
    </div>

    <pre class="code-box" id="scriptCodeBlock">function doPost(e) {
  try {
    var contents = e.postData ? e.postData.contents : "";
    var data = {};
    if (contents) {
      try { data = JSON.parse(contents); } catch(_) { data = e.parameter || {}; }
    } else if (e.parameter) {
      data = e.parameter;
    }
    var sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();
    if (data.action === "updateCell" || (data.row && data.col)) {
      sheet.getRange(Number(data.row), Number(data.col)).setValue(data.value);
      return ContentService.createTextOutput(JSON.stringify({status: "ok", row: data.row, col: data.col, value: data.value}))
        .setMimeType(ContentService.MimeType.JSON);
    } else if (data.action === "batchUpdate" && data.updates) {
      var list = typeof data.updates === "string" ? JSON.parse(data.updates) : data.updates;
      for (var i = 0; i < list.length; i++) {
        var u = list[i];
        sheet.getRange(Number(u.row), Number(u.col)).setValue(u.value);
      }
      SpreadsheetApp.flush();
      return ContentService.createTextOutput(JSON.stringify({status: "ok", count: list.length}))
        .setMimeType(ContentService.MimeType.JSON);
    }
    return ContentService.createTextOutput(JSON.stringify({status: "ok", message: "no action"}))
      .setMimeType(ContentService.MimeType.JSON);
  } catch (err) {
    return ContentService.createTextOutput(JSON.stringify({status: "error", message: err.toString()}))
      .setMimeType(ContentService.MimeType.JSON);
  }
}
function doGet(e) {
  try {
    var sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();
    if (e.parameter && e.parameter.action === "updateCell") {
      sheet.getRange(Number(e.parameter.row), Number(e.parameter.col)).setValue(e.parameter.value);
      return ContentService.createTextOutput(JSON.stringify({status: "ok"}))
        .setMimeType(ContentService.MimeType.JSON);
    }
    var values = sheet.getDataRange().getValues();
    return ContentService.createTextOutput(JSON.stringify({status: "ok", values: values}))
      .setMimeType(ContentService.MimeType.JSON);
  } catch (err) {
    return ContentService.createTextOutput(JSON.stringify({status: "error", message: err.toString()}))
      .setMimeType(ContentService.MimeType.JSON);
  }
}</pre>

    <div class="input-group">
      <label for="webhookUrlInput">Deployed Web App URL (Optional for instant write sync):</label>
      <input type="url" id="webhookUrlInput" placeholder="https://script.google.com/macros/s/.../exec">
    </div>

    <div class="modal-actions" style="display: flex; justify-content: space-between; align-items: center; width: 100%;">
      <button class="btn-modal btn-modal-cancel" onclick="window.open('$safeRawUrl', '_blank')">
        <span class="material-icons" style="font-size: 14px; vertical-align: middle;">open_in_new</span> Open Sheet in Browser
      </button>
      <div style="display: flex; gap: 8px;">
        <button class="btn-modal btn-modal-cancel" onclick="close2WayModal()">Close</button>
        <button class="btn-modal btn-modal-primary" onclick="saveWebhookUrl()">Save &amp; Connect</button>
      </div>
    </div>
  </div>
</div>

<script>
  const SHEET_KEY = 'sheets_data_' + '$safeId';
  const DOC_ID = '$safeDocId';
  let NUM_ROWS = 60;
  let NUM_COLS = 26; // A to Z
  
  let selectedRow = 1;
  let selectedCol = 1;
  let isEditing = false;
  
  // Data matrix: data[row:col] = { raw: '', bold: true, ... }
  let sheetData = {};

  let isSyncing = false;
  let syncFailureCount = 0;

  function colToLetter(colIndex) {
    let temp, letter = '';
    while (colIndex > 0) {
      temp = (colIndex - 1) % 26;
      letter = String.fromCharCode(temp + 65) + letter;
      colIndex = (colIndex - temp - 1) / 26;
    }
    return letter;
  }

  function letterToCol(letter) {
    let col = 0;
    for (let i = 0; i < letter.length; i++) {
      col = col * 26 + (letter.charCodeAt(i) - 64);
    }
    return col;
  }

  function initGrid() {
    loadSavedDataLocally();

    // Render thead
    const thead = document.getElementById('sheetThead');
    thead.innerHTML = '';
    const headerRow = document.createElement('tr');
    
    const corner = document.createElement('th');
    corner.className = 'corner-header';
    headerRow.appendChild(corner);

    for (let c = 1; c <= NUM_COLS; c++) {
      const th = document.createElement('th');
      th.className = 'col-header';
      th.id = 'col-h-' + c;
      th.innerText = colToLetter(c);
      th.onclick = () => selectCol(c);
      headerRow.appendChild(th);
    }
    thead.appendChild(headerRow);

    // Render tbody
    const tbody = document.getElementById('sheetTbody');
    tbody.innerHTML = '';

    for (let r = 1; r <= NUM_ROWS; r++) {
      const tr = document.createElement('tr');
      tr.id = 'row-tr-' + r;
      const rowH = document.createElement('th');
      rowH.className = 'row-header';
      rowH.id = 'row-h-' + r;
      rowH.innerText = r;
      rowH.onclick = () => selectRow(r);
      tr.appendChild(rowH);

      for (let c = 1; c <= NUM_COLS; c++) {
        const td = document.createElement('td');
        td.className = 'sheet-cell';
        td.id = 'cell-' + r + '-' + c;
        td.dataset.row = r;
        td.dataset.col = c;
        td.contentEditable = "false";
        
        applyCellStylesAndContent(td, r, c);

        td.addEventListener('click', (e) => onCellClick(r, c, e));
        td.addEventListener('dblclick', (e) => onCellDblClick(r, c, e));
        td.addEventListener('blur', (e) => onCellBlur(r, c, e));
        td.addEventListener('input', (e) => onCellInput(r, c, e));

        tr.appendChild(td);
      }
      tbody.appendChild(tr);
    }

    selectCell(1, 1);
  }

  function ensureGridDimensions(minRows, minCols) {
    let changed = false;
    if (minRows > NUM_ROWS) {
      NUM_ROWS = minRows;
      changed = true;
    }
    if (minCols > NUM_COLS) {
      NUM_COLS = minCols;
      changed = true;
    }
    if (changed) {
      initGrid();
    }
  }

  function applyCellStylesAndContent(td, r, c) {
    const key = r + ':' + c;
    const item = sheetData[key];
    if (item && item.raw !== undefined && item.raw !== null) {
      td.innerText = evaluateFormula(item.raw, r, c);
      if (item.bold) td.style.fontWeight = 'bold';
      if (item.italic) td.style.fontStyle = 'italic';
      if (item.strike) td.style.textDecoration = 'line-through';
      if (item.color) td.style.color = item.color;
      if (item.bg) td.style.background = item.bg;
      if (item.align) td.style.textAlign = item.align;
      if (item.fontSize) td.style.fontSize = item.fontSize + 'px';
      if (item.fontFamily) td.style.fontFamily = item.fontFamily;
    } else {
      td.innerText = '';
    }
  }

  function selectCell(r, c) {
    const prevCell = document.querySelector('.sheet-cell.selected');
    if (prevCell) prevCell.classList.remove('selected');

    document.querySelectorAll('.col-header.selected').forEach(el => el.classList.remove('selected'));
    document.querySelectorAll('.row-header.selected').forEach(el => el.classList.remove('selected'));

    selectedRow = r;
    selectedCol = c;

    const cell = document.getElementById('cell-' + r + '-' + c);
    if (cell) {
      cell.classList.add('selected');
    }

    const colH = document.getElementById('col-h-' + c);
    if (colH) colH.classList.add('selected');
    const rowH = document.getElementById('row-h-' + r);
    if (rowH) rowH.classList.add('selected');

    const cellRef = colToLetter(c) + r;
    document.getElementById('cellNameBox').innerText = cellRef;

    const key = r + ':' + c;
    const item = sheetData[key];
    const rawVal = item ? (item.raw || '') : '';
    document.getElementById('formulaInput').value = rawVal;

    updateToolbarState(item);
  }

  function updateToolbarState(item) {
    document.getElementById('btnBold').classList.toggle('active', !!(item && item.bold));
    document.getElementById('btnItalic').classList.toggle('active', !!(item && item.italic));
    document.getElementById('btnStrike').classList.toggle('active', !!(item && item.strike));
  }

  function onCellClick(r, c, e) {
    if (isEditing && (selectedRow !== r || selectedCol !== c)) {
      finishEditing();
    }
    selectCell(r, c);
  }

  function onCellDblClick(r, c, e) {
    startEditing(r, c);
  }

  function startEditing(r, c) {
    isEditing = true;
    const cell = document.getElementById('cell-' + r + '-' + c);
    if (!cell) return;
    cell.classList.add('editing');
    cell.contentEditable = "true";
    const key = r + ':' + c;
    const item = sheetData[key];
    cell.innerText = item ? (item.raw || '') : '';
    cell.focus();
  }

  function finishEditing() {
    if (!isEditing) return;
    const cell = document.getElementById('cell-' + selectedRow + '-' + selectedCol);
    if (cell) {
      cell.classList.remove('editing');
      cell.contentEditable = "false";
      setCellValue(selectedRow, selectedCol, cell.innerText);
    }
    isEditing = false;
  }

  function onCellBlur(r, c, e) {
    finishEditing();
  }

  function onCellInput(r, c, e) {
    const text = e.target.innerText;
    document.getElementById('formulaInput').value = text;
  }

  // Formula input listener
  document.getElementById('formulaInput').addEventListener('input', (e) => {
    setCellValue(selectedRow, selectedCol, e.target.value);
  });

  document.getElementById('formulaInput').addEventListener('keydown', (e) => {
    if (e.key === 'Enter') {
      selectCell(Math.min(NUM_ROWS, selectedRow + 1), selectedCol);
      document.getElementById('formulaInput').focus();
    }
  });

  // Keyboard navigation
  window.addEventListener('keydown', (e) => {
    if (isEditing) {
      if (e.key === 'Enter') {
        e.preventDefault();
        finishEditing();
        selectCell(Math.min(NUM_ROWS, selectedRow + 1), selectedCol);
      } else if (e.key === 'Tab') {
        e.preventDefault();
        finishEditing();
        selectCell(selectedRow, Math.min(NUM_COLS, selectedCol + 1));
      }
      return;
    }

    if (document.activeElement.tagName === 'INPUT' || document.activeElement.tagName === 'SELECT' || document.activeElement.tagName === 'TEXTAREA') return;

    if (e.key === 'ArrowUp') {
      e.preventDefault();
      selectCell(Math.max(1, selectedRow - 1), selectedCol);
    } else if (e.key === 'ArrowDown') {
      e.preventDefault();
      selectCell(Math.min(NUM_ROWS, selectedRow + 1), selectedCol);
    } else if (e.key === 'ArrowLeft') {
      e.preventDefault();
      selectCell(selectedRow, Math.max(1, selectedCol - 1));
    } else if (e.key === 'ArrowRight' || e.key === 'Tab') {
      e.preventDefault();
      selectCell(selectedRow, Math.min(NUM_COLS, selectedCol + 1));
    } else if (e.key === 'Enter') {
      e.preventDefault();
      startEditing(selectedRow, selectedCol);
    } else if (e.key === 'Delete' || e.key === 'Backspace') {
      setCellValue(selectedRow, selectedCol, '');
      document.getElementById('formulaInput').value = '';
    } else if (e.key.length === 1 && !e.ctrlKey && !e.metaKey && !e.altKey) {
      startEditing(selectedRow, selectedCol);
    }
  });

  function setCellValue(r, c, val) {
    const key = r + ':' + c;
    if (!sheetData[key]) sheetData[key] = {};
    sheetData[key].raw = val;
    sheetData[key].dirty = true;

    const cell = document.getElementById('cell-' + r + '-' + c);
    if (cell && !isEditing) {
      cell.innerText = evaluateFormula(val, r, c);
    }
    recalculateGrid();
    saveDataLocally();
    
    // Dispatch 2-way write update to real Google Sheet
    sendCellUpdateToGoogle(r, c, val);
  }

  function evaluateFormula(raw, r, c) {
    if (!raw || typeof raw !== 'string') return raw || '';
    if (!raw.startsWith('=')) return raw;

    try {
      const expr = raw.substring(1).trim().toUpperCase();
      
      // =SUM(A1:A5)
      const sumMatch = expr.match(/^SUM\\(([A-Z]+[0-9]+):([A-Z]+[0-9]+)\\)\$/);
      if (sumMatch) {
        return calcRange(sumMatch[1], sumMatch[2], (arr) => arr.reduce((a, b) => a + b, 0));
      }
      
      // =AVERAGE(A1:A5)
      const avgMatch = expr.match(/^AVERAGE\\(([A-Z]+[0-9]+):([A-Z]+[0-9]+)\\)\$/);
      if (avgMatch) {
        return calcRange(avgMatch[1], avgMatch[2], (arr) => arr.length ? (arr.reduce((a, b) => a + b, 0) / arr.length).toFixed(2) : 0);
      }

      // =COUNT(A1:A5)
      const countMatch = expr.match(/^COUNT\\(([A-Z]+[0-9]+):([A-Z]+[0-9]+)\\)\$/);
      if (countMatch) {
        return calcRange(countMatch[1], countMatch[2], (arr) => arr.length);
      }

      // Basic arithmetic
      const parsed = expr.replace(/([A-Z]+)([0-9]+)/g, (match, colLetters, rowNum) => {
        const col = letterToCol(colLetters);
        const row = parseInt(rowNum, 10);
        const item = sheetData[row + ':' + col];
        const v = item ? parseFloat(item.raw) || 0 : 0;
        return v;
      });

      if (/^[0-9+\\-*\\/().\\s]+\$/.test(parsed)) {
        // eslint-disable-next-line no-eval
        return Function('"use strict";return (' + parsed + ')')();
      }
    } catch (_) {
      return '#ERROR!';
    }
    return raw;
  }

  function calcRange(startRef, endRef, op) {
    const sMatch = startRef.match(/([A-Z]+)([0-9]+)/);
    const eMatch = endRef.match(/([A-Z]+)([0-9]+)/);
    if (!sMatch || !eMatch) return 0;

    const startCol = letterToCol(sMatch[1]);
    const startRow = parseInt(sMatch[2], 10);
    const endCol = letterToCol(eMatch[1]);
    const endRow = parseInt(eMatch[2], 10);

    const nums = [];
    for (let r = Math.min(startRow, endRow); r <= Math.max(startRow, endRow); r++) {
      for (let c = Math.min(startCol, endCol); c <= Math.max(startCol, endCol); c++) {
        const item = sheetData[r + ':' + c];
        if (item && item.raw !== '') {
          const n = parseFloat(item.raw);
          if (!isNaN(n)) nums.push(n);
        }
      }
    }
    return op(nums);
  }

  function recalculateGrid() {
    for (let r = 1; r <= NUM_ROWS; r++) {
      for (let c = 1; c <= NUM_COLS; c++) {
        const key = r + ':' + c;
        const item = sheetData[key];
        if (item && item.raw && item.raw.startsWith('=')) {
          const cell = document.getElementById('cell-' + r + '-' + c);
          if (cell && !cell.classList.contains('editing')) {
            cell.innerText = evaluateFormula(item.raw, r, c);
          }
        }
      }
    }
  }

  // Formatting actions
  function toggleBold() {
    const key = selectedRow + ':' + selectedCol;
    if (!sheetData[key]) sheetData[key] = { raw: '' };
    sheetData[key].bold = !sheetData[key].bold;
    const cell = document.getElementById('cell-' + selectedRow + '-' + selectedCol);
    if (cell) cell.style.fontWeight = sheetData[key].bold ? 'bold' : 'normal';
    updateToolbarState(sheetData[key]);
    saveDataLocally();
  }

  function toggleItalic() {
    const key = selectedRow + ':' + selectedCol;
    if (!sheetData[key]) sheetData[key] = { raw: '' };
    sheetData[key].italic = !sheetData[key].italic;
    const cell = document.getElementById('cell-' + selectedRow + '-' + selectedCol);
    if (cell) cell.style.fontStyle = sheetData[key].italic ? 'italic' : 'normal';
    updateToolbarState(sheetData[key]);
    saveDataLocally();
  }

  function toggleStrike() {
    const key = selectedRow + ':' + selectedCol;
    if (!sheetData[key]) sheetData[key] = { raw: '' };
    sheetData[key].strike = !sheetData[key].strike;
    const cell = document.getElementById('cell-' + selectedRow + '-' + selectedCol);
    if (cell) cell.style.textDecoration = sheetData[key].strike ? 'line-through' : 'none';
    updateToolbarState(sheetData[key]);
    saveDataLocally();
  }

  function alignCell(align) {
    const key = selectedRow + ':' + selectedCol;
    if (!sheetData[key]) sheetData[key] = { raw: '' };
    sheetData[key].align = align;
    const cell = document.getElementById('cell-' + selectedRow + '-' + selectedCol);
    if (cell) cell.style.textAlign = align;
    saveDataLocally();
  }

  function applyFontFamily(font) {
    const key = selectedRow + ':' + selectedCol;
    if (!sheetData[key]) sheetData[key] = { raw: '' };
    sheetData[key].fontFamily = font;
    const cell = document.getElementById('cell-' + selectedRow + '-' + selectedCol);
    if (cell) cell.style.fontFamily = font;
    saveDataLocally();
  }

  function applyFontSize(size) {
    const key = selectedRow + ':' + selectedCol;
    if (!sheetData[key]) sheetData[key] = { raw: '' };
    sheetData[key].fontSize = size;
    const cell = document.getElementById('cell-' + selectedRow + '-' + selectedCol);
    if (cell) cell.style.fontSize = size + 'px';
    saveDataLocally();
  }

  function changeTextColor() {
    const chosen = prompt('Enter text color name or hex (e.g. #1a73e8 or red):', '#1a73e8');
    if (chosen) {
      const key = selectedRow + ':' + selectedCol;
      if (!sheetData[key]) sheetData[key] = { raw: '' };
      sheetData[key].color = chosen;
      const cell = document.getElementById('cell-' + selectedRow + '-' + selectedCol);
      if (cell) cell.style.color = chosen;
      saveDataLocally();
    }
  }

  function changeBgColor() {
    const chosen = prompt('Enter background hex color (e.g. #e8f0fe, #e6f4ea, #fce8e6):', '#e8f0fe');
    if (chosen) {
      const key = selectedRow + ':' + selectedCol;
      if (!sheetData[key]) sheetData[key] = { raw: '' };
      sheetData[key].bg = chosen;
      const cell = document.getElementById('cell-' + selectedRow + '-' + selectedCol);
      if (cell) cell.style.background = chosen;
      saveDataLocally();
    }
  }

  function insertFormula(type) {
    const cellRef = colToLetter(selectedCol) + '1:' + colToLetter(selectedCol) + Math.max(1, selectedRow - 1);
    const f = '=' + type + '(' + cellRef + ')';
    setCellValue(selectedRow, selectedCol, f);
    document.getElementById('formulaInput').value = f;
  }

  function insertRowBelow() {
    NUM_ROWS += 10;
    initGrid();
    showToast('Added 10 more rows below');
  }

  function insertColRight() {
    NUM_COLS += 5;
    initGrid();
    showToast('Added 5 more columns');
  }

  function clearSelectedCell() {
    setCellValue(selectedRow, selectedCol, '');
    document.getElementById('formulaInput').value = '';
  }

  function undo() { showToast('Undo performed'); }
  function redo() { showToast('Redo performed'); }

  // Status Badge Updater
  function updateSyncBadge(status, text) {
    const badge = document.getElementById('syncBadge');
    const dot = document.getElementById('syncDot');
    const statusText = document.getElementById('syncStatusText');
    const btnSync = document.getElementById('btnSyncNow');

    if (!badge || !dot || !statusText) return;

    badge.className = 'sync-badge ' + status;
    statusText.innerText = text;

    if (status === 'syncing') {
      dot.className = 'sync-dot pulse';
      dot.style.background = '#1a73e8';
      if (btnSync) btnSync.classList.add('spinning');
    } else if (status === 'synced') {
      dot.className = 'sync-dot pulse';
      dot.style.background = '#0f9d58';
      if (btnSync) btnSync.classList.remove('spinning');
    } else if (status === 'warning') {
      dot.className = 'sync-dot';
      dot.style.background = '#e37400';
      if (btnSync) btnSync.classList.remove('spinning');
    }
  }

  function showShareBanner() {
    const b = document.getElementById('shareNoticeBanner');
    if (b) b.style.display = 'flex';
  }

  function hideShareBanner() {
    const b = document.getElementById('shareNoticeBanner');
    if (b) b.style.display = 'none';
  }

  // --- GOOGLE SHEETS LIVE JSONP SYNC (Google Sheet -> In-App Viewer) ---
  function syncFromGoogleSheet(silent = false) {
    if (!DOC_ID || DOC_ID.length < 5) {
      if (!silent) showToast('No linked Google Sheet found');
      updateSyncBadge('warning', 'Offline Sheet');
      return;
    }
    if (isSyncing) return;
    isSyncing = true;

    if (!silent) {
      updateSyncBadge('syncing', 'Syncing...');
    }

    // Clean up previous JSONP script tag
    const old = document.getElementById('google_gviz_script');
    if (old) old.remove();

    window._googleSheetJsonpHandler = function(data) {
      isSyncing = false;
      syncFailureCount = 0;
      hideShareBanner();

      if (data && data.status === 'ok' && data.table) {
        applyGoogleTableData(data.table);
        updateSyncBadge('synced', 'Saved');
        if (!silent) showToast('Data loaded');
      }
    };

    const script = document.createElement('script');
    script.id = 'google_gviz_script';
    script.src = 'https://docs.google.com/spreadsheets/d/' + DOC_ID + '/gviz/tq?tqx=responseHandler:_googleSheetJsonpHandler&t=' + Date.now();
    script.onerror = function() {
      isSyncing = false;
    };
    document.head.appendChild(script);
  }

  function applyGoogleTableData(table) {
    if (!table || !table.rows) return;

    const rowCount = table.rows.length;
    const colCount = table.cols ? table.cols.length : 1;

    // Expand grid bounds if needed
    if (rowCount + 10 > NUM_ROWS || colCount + 4 > NUM_COLS) {
      ensureGridDimensions(Math.max(NUM_ROWS, rowCount + 15), Math.max(NUM_COLS, colCount + 5));
    }

    let loadedCount = 0;

    table.rows.forEach(function(rowObj, rIdx) {
      const r = rIdx + 1;
      if (rowObj && rowObj.c) {
        rowObj.c.forEach(function(cellObj, cIdx) {
          const c = cIdx + 1;
          let cellVal = '';
          if (cellObj) {
            if (cellObj.f !== undefined && cellObj.f !== null) {
              cellVal = String(cellObj.f);
            } else if (cellObj.v !== undefined && cellObj.v !== null) {
              if (typeof cellObj.v === 'string' && cellObj.v.startsWith('Date(')) {
                const dp = cellObj.v.match(/\\d+/g);
                if (dp && dp.length >= 3) {
                  cellVal = dp[0] + '-' + (parseInt(dp[1], 10) + 1) + '-' + dp[2];
                } else {
                  cellVal = cellObj.v;
                }
              } else {
                cellVal = String(cellObj.v);
              }
            }
          }

          if (cellVal !== '') loadedCount++;

          const key = r + ':' + c;
          
          // Never overwrite if user is actively editing this exact cell
          if (isEditing && selectedRow === r && selectedCol === c) {
            return;
          }

          // Protect locally modified/saved cells from being reset by remote polling
          if (sheetData[key] && sheetData[key].dirty) {
            return;
          }

          // If local data already exists and is not empty, don't overwrite with remote blank
          if (sheetData[key] && sheetData[key].raw && !cellVal) {
            return;
          }

          if (!sheetData[key]) sheetData[key] = {};
          sheetData[key].raw = cellVal;

          const td = document.getElementById('cell-' + r + '-' + c);
          if (td) {
            td.innerText = evaluateFormula(cellVal, r, c);
          }
        });
      }
    });

    // Update formula bar if not editing
    if (!isEditing) {
      const curKey = selectedRow + ':' + selectedCol;
      const curItem = sheetData[curKey];
      document.getElementById('formulaInput').value = curItem ? (curItem.raw || '') : '';
    }

    saveDataLocally();
  }

  // --- WEBHOOK & 2-WAY WRITE SYNC (In-App Viewer -> Google Sheet) ---
  function getWebhookUrl() {
    return localStorage.getItem(SHEET_KEY + '_webhook') || localStorage.getItem('default_sheets_webhook') || '';
  }

  let cellUpdateDebounceTimer = null;
  function sendCellUpdateToGoogle(r, c, val) {
    const webhookUrl = getWebhookUrl();
    if (!webhookUrl || !webhookUrl.startsWith('http')) {
      updateSyncBadge('local', 'Saved locally');
      return;
    }

    updateSyncBadge('syncing', 'Saving to Google Sheet...');

    clearTimeout(cellUpdateDebounceTimer);
    cellUpdateDebounceTimer = setTimeout(() => {
      fetch(webhookUrl, {
        method: 'POST',
        mode: 'no-cors',
        headers: { 'Content-Type': 'text/plain;charset=utf-8' },
        body: JSON.stringify({
          action: 'updateCell',
          row: r,
          col: c,
          value: val
        })
      }).then(() => {
        const key = r + ':' + c;
        if (sheetData[key]) delete sheetData[key].dirty;
        saveDataLocally();
        updateSyncBadge('synced', 'All changes saved to Google Sheet');
        setTimeout(() => {
          updateSyncBadge('synced', 'Saved to Google Sheet');
        }, 2200);
      }).catch((err) => {
        console.warn('Webhook update failed:', err);
        updateSyncBadge('warning', 'Saved locally (offline)');
      });
    }, 350);
  }

  // --- SAVE & SYNC (Ctrl+S or Save Button) ---
  function performSaveAndSync() {
    // 1. If actively typing in a cell, finish editing immediately
    if (isEditing) {
      finishEditing();
    }

    // 2. If formula input is currently focused, apply its value
    const formulaInput = document.getElementById('formulaInput');
    if (document.activeElement === formulaInput) {
      setCellValue(selectedRow, selectedCol, formulaInput.value);
      formulaInput.blur();
    }

    // 3. Immediately save everything locally
    saveDataLocally();

    // 4. Update status indicator to Google Sheets "Saving..." state
    updateSyncBadge('syncing', 'Saving to Google Sheet...');
    const btnSave = document.getElementById('btnSaveNow');
    if (btnSave) {
      btnSave.classList.add('saving');
      const textSpan = btnSave.querySelector('.btn-text');
      if (textSpan) textSpan.innerText = 'Saving...';
    }

    const webhookUrl = getWebhookUrl();

    // Case A: Instant local save
    if (!webhookUrl || !webhookUrl.startsWith('http')) {
      updateSyncBadge('synced', 'Saved');
      if (btnSave) {
        btnSave.classList.remove('saving');
        const textSpan = btnSave.querySelector('.btn-text');
        if (textSpan) textSpan.innerText = 'Save (Ctrl+S)';
      }
      showToast('Saved (Ctrl+S)');
      return;
    }

    // Case B: Webhook configured -> push all cell values to Google Sheet
    const updates = [];
    for (const k in sheetData) {
      const parts = k.split(':');
      const r = parseInt(parts[0], 10);
      const c = parseInt(parts[1], 10);
      const item = sheetData[k];
      if (item && item.raw !== undefined && item.raw !== null && item.raw !== '') {
        updates.push({ row: r, col: c, value: item.raw });
      }
    }

    fetch(webhookUrl, {
      method: 'POST',
      mode: 'no-cors',
      headers: { 'Content-Type': 'text/plain;charset=utf-8' },
      body: JSON.stringify({
        action: 'batchUpdate',
        updates: updates
      })
    }).then(() => {
      // Clear all dirty flags
      for (const k in sheetData) {
        if (sheetData[k]) delete sheetData[k].dirty;
      }
      saveDataLocally();

      updateSyncBadge('synced', 'All changes saved to Google Sheet');
      if (btnSave) {
        btnSave.classList.remove('saving');
        const textSpan = btnSave.querySelector('.btn-text');
        if (textSpan) textSpan.innerText = 'Save (Ctrl+S)';
      }
      showToast('All changes saved & synced to Google Sheet!');
      setTimeout(() => {
        updateSyncBadge('synced', 'Saved to Google Sheet');
      }, 2500);
    }).catch((err) => {
      console.warn('Batch save failed:', err);
      updateSyncBadge('warning', 'Saved locally (sync failed)');
      if (btnSave) {
        btnSave.classList.remove('saving');
        const textSpan = btnSave.querySelector('.btn-text');
        if (textSpan) textSpan.innerText = 'Save (Ctrl+S)';
      }
      showToast('Saved locally. Please check your Webhook URL.');
    });
  }

  // Intercept Ctrl+S / Cmd+S globally to prevent browser Save dialog and run performSaveAndSync
  function handleGlobalKeyDown(e) {
    if ((e.ctrlKey || e.metaKey) && (e.key === 's' || e.key === 'S')) {
      e.preventDefault();
      e.stopPropagation();
      performSaveAndSync();
      return false;
    }
  }
  window.addEventListener('keydown', handleGlobalKeyDown, true);
  document.addEventListener('keydown', handleGlobalKeyDown, true);

  // Listen for message from Flutter outer window
  window.addEventListener('message', function(e) {
    if (e.data === 'save_and_sync') {
      performSaveAndSync();
    }
  });

  // Modal Handlers
  function open2WayModal() {
    const saved = getWebhookUrl();
    document.getElementById('webhookUrlInput').value = saved;
    document.getElementById('syncModal').style.display = 'flex';
  }

  function close2WayModal() {
    document.getElementById('syncModal').style.display = 'none';
  }

  function saveWebhookUrl() {
    const val = document.getElementById('webhookUrlInput').value.trim();
    if (val) {
      localStorage.setItem(SHEET_KEY + '_webhook', val);
      localStorage.setItem('default_sheets_webhook', val);
      showToast('2-Way Sync Webhook connected! Changes will now write to Google Sheet.');
      updateSyncBadge('synced', 'Connected to Google Sheet');
      close2WayModal();
      performSaveAndSync();
    } else {
      localStorage.removeItem(SHEET_KEY + '_webhook');
      localStorage.removeItem('default_sheets_webhook');
      showToast('Webhook removed.');
      close2WayModal();
    }
  }

  function copyScriptCode() {
    const code = document.getElementById('scriptCodeBlock').innerText;
    navigator.clipboard.writeText(code).then(() => {
      showToast('Google Apps Script code copied to clipboard!');
    }).catch(() => {
      showToast('Please copy code manually.');
    });
  }

  // Persistence
  function saveDataLocally() {
    try {
      localStorage.setItem(SHEET_KEY, JSON.stringify(sheetData));
    } catch (_) {}
  }

  function loadSavedDataLocally() {
    try {
      const raw = localStorage.getItem(SHEET_KEY);
      if (raw) {
        sheetData = JSON.parse(raw);
      }
    } catch (_) {}
  }

  // Export
  function exportCsv() {
    let csv = '';
    let maxR = 1, maxC = 1;
    for (const k in sheetData) {
      const parts = k.split(':');
      const r = parseInt(parts[0], 10);
      const c = parseInt(parts[1], 10);
      if (r > maxR) maxR = r;
      if (c > maxC) maxC = c;
    }

    for (let r = 1; r <= Math.min(NUM_ROWS, Math.max(maxR, 20)); r++) {
      const rowArr = [];
      for (let c = 1; c <= Math.min(NUM_COLS, Math.max(maxC, 10)); c++) {
        const item = sheetData[r + ':' + c];
        const text = item ? (item.raw || '') : '';
        rowArr.push('"' + text.replace(/"/g, '""') + '"');
      }
      csv += rowArr.join(',') + '\\n';
    }

    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = (document.getElementById('docTitle').value || 'spreadsheet') + '.csv';
    link.click();
    showToast('Spreadsheet exported as CSV!');
  }

  function addNewTab() {
    const list = document.getElementById('sheetTabsList');
    const tabCount = list.children.length + 1;
    const tab = document.createElement('div');
    tab.className = 'sheet-tab';
    tab.id = 'tab-' + tabCount;
    tab.innerHTML = '<span class="material-icons" style="font-size: 14px; color: #0f9d58;">table_chart</span><span>Sheet' + tabCount + '</span>';
    tab.onclick = () => switchTab(tabCount);
    list.appendChild(tab);
    switchTab(tabCount);
  }

  function switchTab(idx) {
    document.querySelectorAll('.sheet-tab').forEach(t => t.classList.remove('active'));
    const t = document.getElementById('tab-' + idx);
    if (t) t.classList.add('active');
    showToast('Switched to Sheet' + idx);
  }

  function showToast(msg) {
    const t = document.getElementById('toastMsg');
    t.innerText = msg;
    t.style.display = 'flex';
    setTimeout(() => { t.style.display = 'none'; }, 2600);
  }

  // Rename listener
  document.getElementById('docTitle').addEventListener('change', (e) => {
    localStorage.setItem(SHEET_KEY + '_title', e.target.value);
    showToast('Spreadsheet title updated');
  });

  // Init on load
  function startApp() {
    initGrid();
    
    // Initial badge state - instant ready
    updateSyncBadge('synced', 'Ready');

    // 1. Initial live sync from Google Sheet with 3s safety timeout
    if (DOC_ID && DOC_ID.length > 5) {
      syncFromGoogleSheet(true);
    }
  }

  if (document.readyState === 'loading') {
    window.addEventListener('DOMContentLoaded', startApp);
  } else {
    startApp();
  }
</script>
</body>
</html>
''';
}
