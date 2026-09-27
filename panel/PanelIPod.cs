// Panel de control del iPod touch 1G emulado (qemu-ios en WSL Debian).
// Compilar: csc /target:winexe /out:"Panel iPod.exe" PanelIPod.cs  (ver compilar.bat)
// Solo ejecuta comandos fijos de scripts/ctl.py dentro de WSL; no pide ni envía datos a ningún sitio.
using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

class PanelIPod : Form
{
    const string Distro = "Debian";
    const string Ctl = "/mnt/f/Descargas/iternalipod/scripts/ctl.py";
    const string Capturas = @"F:\Descargas\iternalipod\capturas";
    static readonly string[] Modos = { "skankphone", "original", "springboard" };
    static readonly string[] NombresModos = { "SkankPhone (shell del sistema)", "iPhone OS 1.1 original", "SpringBoard parcheado" };

    static readonly Color Fondo = Color.FromArgb(28, 28, 32);
    static readonly Color Tarjeta = Color.FromArgb(44, 44, 52);
    static readonly Color Texto = Color.FromArgb(235, 235, 240);
    static readonly Color Azul = Color.FromArgb(10, 60, 255);
    static readonly Color Verde = Color.FromArgb(40, 170, 90);
    static readonly Color Rojo = Color.FromArgb(200, 50, 50);

    ComboBox modo;
    Label estado, mensaje;
    Button[] botones;
    bool ocupado;
    Timer sondeo;

    [STAThread]
    static void Main()
    {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        Application.Run(new PanelIPod());
    }

    PanelIPod()
    {
        Text = "iPod touch 1G · Panel";
        FormBorderStyle = FormBorderStyle.FixedSingle;
        MaximizeBox = false;
        StartPosition = FormStartPosition.CenterScreen;
        BackColor = Fondo;
        ForeColor = Texto;
        Font = new Font("Segoe UI", 10f);
        ClientSize = new Size(360, 470);
        KeyPreview = true;
        try { Icon = Icon.ExtractAssociatedIcon(Application.ExecutablePath); } catch { }

        var titulo = new Label { Text = "SkankPhone · qemu-ios", Font = new Font("Segoe UI Semibold", 15f),
                                 AutoSize = false, Bounds = new Rectangle(16, 12, 328, 32) };
        estado = new Label { Text = "● comprobando…", AutoSize = false, Bounds = new Rectangle(16, 44, 328, 22),
                             ForeColor = Color.Gray };
        var lblModo = new Label { Text = "Modo de arranque", AutoSize = false, Bounds = new Rectangle(16, 76, 328, 20),
                                  ForeColor = Color.Silver, Font = new Font("Segoe UI", 9f) };
        modo = new ComboBox { DropDownStyle = ComboBoxStyle.DropDownList, Bounds = new Rectangle(16, 98, 328, 28),
                              BackColor = Tarjeta, ForeColor = Texto, FlatStyle = FlatStyle.Flat };
        modo.Items.AddRange(NombresModos);
        modo.SelectedIndex = 0;
        Controls.AddRange(new Control[] { titulo, estado, lblModo, modo });

        var reinicio = Boton("⟳  Reinicio rápido  (F5)", Azul, new Rectangle(16, 140, 328, 58), 13f,
                             delegate { Ejecutar("reiniciar " + ModoActual(), "Reiniciando…"); });
        var encender = Boton("▶  Encender", Verde, new Rectangle(16, 210, 160, 44), 11f,
                             delegate { Ejecutar("encender " + ModoActual(), "Encendiendo…"); });
        var apagar = Boton("■  Apagar", Rojo, new Rectangle(184, 210, 160, 44), 11f,
                           delegate { Ejecutar("apagar", "Apagando…"); });
        var home = Boton("⌂  Home  (F6)", Tarjeta, new Rectangle(16, 266, 160, 44), 11f,
                         delegate { Ejecutar("home", "Home…"); });
        var power = Boton("⏻  Reposo  (F7)", Tarjeta, new Rectangle(184, 266, 160, 44), 11f,
                          delegate { Ejecutar("power", "Reposo…"); });
        var captura = Boton("📷  Captura  (F8)", Tarjeta, new Rectangle(16, 322, 160, 44), 11f,
                            delegate { Ejecutar("captura", "Capturando…"); });
        var carpeta = Boton("📂  Capturas", Tarjeta, new Rectangle(184, 322, 160, 44), 11f,
                            delegate { Abrir(Capturas); });
        var log = Boton("📄  Ver log de la consola serie", Tarjeta, new Rectangle(16, 378, 328, 36), 10f,
                        delegate { Abrir(@"\\wsl.localhost\" + Distro + @"\root\iternalipod\serial_" + ModoActual() + ".log"); });
        botones = new[] { reinicio, encender, apagar, home, power, captura };

        mensaje = new Label { AutoSize = false, Bounds = new Rectangle(16, 424, 328, 40), ForeColor = Color.Silver,
                              Font = new Font("Segoe UI", 9f), Text = "El táctil se usa con el ratón en la ventana del iPod." };
        Controls.Add(mensaje);

        KeyDown += delegate(object s, KeyEventArgs e)
        {
            if (e.KeyCode == Keys.F5) reinicio.PerformClick();
            else if (e.KeyCode == Keys.F6) home.PerformClick();
            else if (e.KeyCode == Keys.F7) power.PerformClick();
            else if (e.KeyCode == Keys.F8) captura.PerformClick();
        };

        sondeo = new Timer { Interval = 3000 };
        sondeo.Tick += delegate { ActualizarEstado(); };
        sondeo.Start();
        Shown += delegate { ActualizarEstado(); };
    }

    Button Boton(string texto, Color color, Rectangle r, float tam, EventHandler click)
    {
        var b = new Button { Text = texto, Bounds = r, BackColor = color, ForeColor = Color.White,
                             FlatStyle = FlatStyle.Flat, Font = new Font("Segoe UI Semibold", tam), Cursor = Cursors.Hand,
                             TabStop = false };
        b.FlatAppearance.BorderSize = 0;
        b.FlatAppearance.MouseOverBackColor = ControlPaint.Light(color, 0.25f);
        b.Click += click;
        Controls.Add(b);
        return b;
    }

    string ModoActual() { return Modos[Math.Max(0, modo.SelectedIndex)]; }

    static string Wsl(string args)
    {
        var psi = new ProcessStartInfo("wsl.exe", "-d " + Distro + " -- python3 " + Ctl + " " + args)
        {
            UseShellExecute = false, CreateNoWindow = true,
            RedirectStandardOutput = true, RedirectStandardError = true,
            StandardOutputEncoding = Encoding.UTF8
        };
        using (var p = Process.Start(psi))
        {
            string salida = p.StandardOutput.ReadToEnd();
            p.StandardError.ReadToEnd();
            p.WaitForExit(60000);
            return salida.Replace("\0", "").Trim();
        }
    }

    async void Ejecutar(string args, string aviso)
    {
        if (ocupado) return;
        ocupado = true;
        foreach (var b in botones) b.Enabled = false;
        mensaje.Text = aviso;
        try
        {
            string r = await Task.Run(() => Wsl(args));
            mensaje.Text = string.IsNullOrEmpty(r) ? "Hecho." : r;
        }
        catch (Exception ex) { mensaje.Text = "Error: " + ex.Message; }
        finally
        {
            foreach (var b in botones) b.Enabled = true;
            ocupado = false;
            ActualizarEstado();
        }
    }

    bool sondeando;
    async void ActualizarEstado()
    {
        if (sondeando) return;
        sondeando = true;
        try
        {
            string r = await Task.Run(() => Wsl("estado"));
            bool on = r.Contains("ENCENDIDO");
            estado.Text = on ? "● Encendido" : "○ Apagado";
            estado.ForeColor = on ? Color.FromArgb(90, 220, 130) : Color.Gray;
        }
        catch { estado.Text = "? WSL no responde"; estado.ForeColor = Color.Orange; }
        finally { sondeando = false; }
    }

    void Abrir(string ruta)
    {
        try
        {
            if (ruta.EndsWith(".log")) Process.Start("notepad.exe", "\"" + ruta + "\"");
            else { Directory.CreateDirectory(ruta); Process.Start("explorer.exe", "\"" + ruta + "\""); }
        }
        catch (Exception ex) { mensaje.Text = "No se pudo abrir: " + ex.Message; }
    }
}
