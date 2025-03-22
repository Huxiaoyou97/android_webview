package com.jsmiao.webapp;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.media.RingtoneManager;
import android.net.Uri;
import android.os.Build;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.core.app.NotificationCompat;

import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;

public class MyFirebaseMessagingService extends FirebaseMessagingService {
    private static final String TAG = "MyFirebaseMsgService";

    /**
     * 当收到新消息时调用
     */
    @Override
    public void onMessageReceived(@NonNull RemoteMessage remoteMessage) {
        // 判断消息是否包含数据
        if (remoteMessage.getData().size() > 0) {
            Log.d(TAG, "Message data payload: " + remoteMessage.getData());
            // 处理数据消息
            // 如果需要长时间处理，应该使用WorkManager将数据交给后台任务处理
        }

        // 检查消息是否包含通知部分
        if (remoteMessage.getNotification() != null) {
            Log.d(TAG, "Message Notification Body: " + remoteMessage.getNotification().getBody());
            sendNotification(remoteMessage.getNotification().getTitle(), 
                            remoteMessage.getNotification().getBody());
        }
    }

    /**
     * 当FCM令牌更新时调用
     */
    @Override
    public void onNewToken(@NonNull String token) {
        Log.d(TAG, "Refreshed token: " + token);

        // 如果需要，可以将新令牌发送到您的应用服务器
        sendRegistrationToServer(token);
    }

    /**
     * 将令牌发送到您的服务器
     */
    private void sendRegistrationToServer(String token) {
        // 实现将令牌发送到自己的服务器的逻辑
        // 这里只是示例，您需要根据自己的服务器API进行实现
        Log.d(TAG, "sendRegistrationTokenToServer: " + token);
    }

    /**
     * 创建并显示自定义通知
     */
    private void sendNotification(String title, String messageBody) {
        Intent intent = new Intent(this, MainActivity.class);
        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
        PendingIntent pendingIntent = PendingIntent.getActivity(this, 0, intent,
                PendingIntent.FLAG_IMMUTABLE);

        String channelId = getString(R.string.default_notification_channel_id);
        Uri defaultSoundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION);
        
        // 获取应用图标作为大图标
        Bitmap largeIcon = BitmapFactory.decodeResource(getResources(), R.mipmap.ic_launcher);
        
        NotificationCompat.Builder notificationBuilder =
                new NotificationCompat.Builder(this, channelId)
                        .setSmallIcon(R.drawable.ic_notification) // 使用合适的通知图标
                        .setLargeIcon(largeIcon) // 使用应用图标作为大图标
                        .setContentTitle(title != null ? title : "通知")
                        .setContentText(messageBody)
                        .setAutoCancel(true)
                        .setSound(defaultSoundUri)
                        .setContentIntent(pendingIntent);

        NotificationManager notificationManager =
                (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);

        // 对于Android 8.0及以上，需要创建通知渠道
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(channelId,
                    "默认通知渠道",
                    NotificationManager.IMPORTANCE_DEFAULT);
            notificationManager.createNotificationChannel(channel);
        }

        notificationManager.notify(0, notificationBuilder.build());
    }
} 