using System;
using System.Collections.Generic;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Windows.Forms;
using Microsoft.Win32;

public class PercentageApplication : ApplicationContext
{
    [System.Runtime.InteropServices.DllImport("user32.dll", CharSet = CharSet.Auto)]
    extern static bool DestroyIcon(IntPtr handle);

    PowerModeChangedEventHandler powerModeHook;
    List<Icon> allIcons = new List<Icon>();
    NotifyIcon trayIcon = new NotifyIcon() { Visible = true };
    Timer timer = new Timer();

    int interval = 1 * 1000;      // Refresh every 1 second
    Color AcDark = Color.Green;   // Dark theme color for AC power
    Color AcLight = Color.Green;  // Light theme color for AC power
    Color DcDark = Color.White;   // Dark theme color for DC (battery) power
    Color DcLight = Color.Black;  // Light theme color for DC (battery) power

    public PercentageApplication()
    {
        // Create icons for all battery percentages (0-100) as well as
        // charging states (AC, DC) and themes (dark, light) at once.
        for (int i = 0; i < 404; i++)
        {
            allIcons.Add(CreateIcon(i % 101, i % 202 < 101, i < 202));
        }

        trayIcon.ContextMenu = new ContextMenu(new MenuItem[] {
            new MenuItem("Exit", Exit)
        });

        powerModeHook = new PowerModeChangedEventHandler((e, sender) => { RefreshIcon(); });

        SystemEvents.PowerModeChanged += powerModeHook;

        trayIcon.MouseClick += new MouseEventHandler((e, sender) => { RefreshIcon(); });

        RefreshIcon();
        timer.Interval = interval;
        timer.Tick += new EventHandler((e, sender) => RefreshIcon());
        timer.Start();
    }

    private Icon CreateIcon(int percentage, bool AC, bool isDark)
    {
        string bitmapText = percentage == 100 ? "██" : percentage.ToString();
        int xOffset = percentage < 10 ? 5 : -5;
        Color fontColor = AC ? (isDark ? AcDark : AcLight) : (isDark ? DcDark : DcLight);
        Icon icon = null;
        Font font = new Font("Arial", 20, FontStyle.Bold);
        using (Bitmap bitmap = new Bitmap(32, 32))
        {
            using (Graphics graphics = Graphics.FromImage(bitmap))
            {
                graphics.Clear(Color.FromArgb(0, 0, 0, 0));
                using (Brush brush = new SolidBrush(fontColor))
                {
                    graphics.TextRenderingHint = System.Drawing.Text.TextRenderingHint.AntiAlias;
                    graphics.DrawString(bitmapText, font, brush, xOffset, 0);
                    graphics.Save();
                }
            }
            System.IntPtr intPtr = bitmap.GetHicon();
            icon = Icon.FromHandle(intPtr).Clone() as Icon;
            DestroyIcon(intPtr);
        }
        return icon;
    }

    private void RefreshIcon()
    {
        PowerStatus powerStatus = SystemInformation.PowerStatus;
        int percentage = (int)(powerStatus.BatteryLifePercent * 100);
        bool isCharging = SystemInformation.PowerStatus.PowerLineStatus == PowerLineStatus.Online;
        bool isDark = false;
        try
        {
            RegistryKey key = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Themes\Personalize");
            isDark = key.GetValue("SystemUsesLightTheme").ToString() == "0";
        }
        catch (Exception) { }
        trayIcon.Icon = allIcons[percentage + (isCharging ? 0 : 101) + (isDark ? 0 : 202)];
        trayIcon.Text = (isCharging ? "Charging," : "") + percentage.ToString() + "%";
    }

    void Exit(object sender, EventArgs e)
    {
        SystemEvents.PowerModeChanged -= powerModeHook;
        trayIcon.Visible = false;
        trayIcon.Dispose();
        foreach (Icon icon in allIcons)
        {
            icon.Dispose();
        }
        allIcons.Clear();
        timer.Stop();
        timer.Dispose();
        Application.Exit();
    }
}

static class Program
{
    [STAThread]
    static void Main()
    {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        Application.Run(new PercentageApplication());
    }
}
