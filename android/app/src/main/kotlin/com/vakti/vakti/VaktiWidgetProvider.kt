package com.vakti.vakti

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home screen widget. Reads the daily tip written from Flutter via the
 * home_widget bridge and renders it. Tapping opens the app at vakti://tip,
 * which writes a fresh tip (blueprint §8.3).
 */
class VaktiWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.vakti_widget).apply {
                val emoji = widgetData.getString("emoji", "🌅") ?: "🌅"
                val title = widgetData.getString("title", "Vakti") ?: "Vakti"
                val primary = widgetData.getString("primary", "") ?: ""
                val secondary = widgetData.getString("secondary", "") ?: ""

                setTextViewText(R.id.widget_emoji, emoji)
                setTextViewText(R.id.widget_title, title)
                setTextViewText(R.id.widget_primary, primary)
                setTextViewText(R.id.widget_secondary, secondary)

                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("vakti://tip"),
                )
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
