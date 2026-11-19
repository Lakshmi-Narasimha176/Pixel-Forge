// AnomalySwap.cs - PSX Anomaly Horror Modular Kit by bitkiln (https://bitkiln.itch.io)
//
// A small Unity example: switches a kit piece between its normal and its anomaly version.
//
// Texture pairs (the same mesh, an anomaly texture on one surface): put this script on the imported piece (GLB through
// glTFast, or OBJ), add one entry to "Texture Swaps" per changed material: the material name of the slot (for
// example "house_wall" - see Catalog/pieces.csv, column "anomaly_slots") and the anomaly PNG from Textures/ (for
// example wallpaper_stripe_sprig_anomaly.png). Only the material slots with exactly that name change (Unity's
// " (Instance)" suffix is ignored), so "st_window" never touches "st_window_lit"; the trims and the wainscot stay as
// they are. The texture and the emission map are set through a
// MaterialPropertyBlock (no material copies).
//
// Mesh pairs (the doorway is gone, the fireplace is bricked up ...): put both pieces in the scene at the same position,
// drag them into Normal Model / Anomaly Model; the anomaly model starts hidden. Companions are objects that leave
// with the anomaly (the door leaf of house_wall_door, the glass door of mart_storefront_door): they are hidden while
// the anomaly is on. Colliders on those objects go with them (SetActive).
//
// This is the swap only: the loop rules (one anomaly or none per loop, turn back or keep going, the loop counter)
// are your game's code; the Godot project's AnomalyManager is a complete example to port.
//
// SetAnomaly(true) shows the anomaly, SetAnomaly(false) the normal look. Works with glTFast shaders
// (baseColorTexture, emissiveTexture), the Built-in Standard shader (_MainTex, _EmissionMap) and URP / HDRP Lit
// (_BaseMap / _BaseColorMap, _EmissionMap / _EmissiveColorMap).

using UnityEngine;

public class AnomalySwap : MonoBehaviour
{
    [System.Serializable]
    public class TextureSwap
    {
        [Tooltip("The material name of the slot that changes, e.g. house_wall or mart_sign (exact name).")]
        public string materialName;
        [Tooltip("The anomaly PNG (Textures/<name>_anomaly.png). Import it with Filter Mode Point, Compression None.")]
        public Texture2D anomalyTexture;
        [Tooltip("Optional: the anomaly emission map (<name>_anomaly_emit.png) for glowing slots.")]
        public Texture2D anomalyEmission;
    }

    [Header("Texture pair")]
    public TextureSwap[] textureSwaps = new TextureSwap[0];

    [Header("Mesh pair")]
    public GameObject normalModel;
    public GameObject anomalyModel;
    [Tooltip("Objects hidden while the anomaly is on (the door leaf in an opening the anomaly closes).")]
    public GameObject[] companions = new GameObject[0];

    [Tooltip("Start with the anomaly on.")]
    public bool startActive = false;

    public bool Active { get; private set; }

    static readonly string[] AlbedoProps = { "_MainTex", "_BaseMap", "_BaseColorMap", "baseColorTexture" };
    static readonly string[] EmissionProps = { "_EmissionMap", "_EmissiveColorMap", "emissiveTexture" };

    Renderer[] _renderers;
    MaterialPropertyBlock _block;

    void Awake()
    {
        _renderers = GetComponentsInChildren<Renderer>(true);
        _block = new MaterialPropertyBlock();
        SetAnomaly(startActive);
    }

    public void SetAnomaly(bool on)
    {
        Active = on;
        if (normalModel != null) normalModel.SetActive(!on);
        if (anomalyModel != null) anomalyModel.SetActive(on);
        foreach (var c in companions)
            if (c != null) c.SetActive(!on);
        if (_renderers == null)
            return;
        foreach (var r in _renderers)
        {
            var mats = r.sharedMaterials;
            for (int i = 0; i < mats.Length; i++)
            {
                var m = mats[i];
                if (m == null)
                    continue;
                r.GetPropertyBlock(_block, i);
                _block.Clear();
                if (on)
                {
                    foreach (var s in textureSwaps)
                    {
                        if (s == null || string.IsNullOrEmpty(s.materialName) || BaseName(m.name) != s.materialName)
                            continue;
                        foreach (var p in AlbedoProps)
                            if (s.anomalyTexture != null && m.HasProperty(p) && m.GetTexture(p) != null)
                                _block.SetTexture(p, s.anomalyTexture);
                        foreach (var p in EmissionProps)
                            if (s.anomalyEmission != null && m.HasProperty(p) && m.GetTexture(p) != null)
                                _block.SetTexture(p, s.anomalyEmission);
                    }
                }
                r.SetPropertyBlock(_block, i);
            }
        }
    }

    // the material name without Unity's " (Instance)" suffixes
    static string BaseName(string n)
    {
        while (n.EndsWith(" (Instance)"))
            n = n.Substring(0, n.Length - " (Instance)".Length);
        return n;
    }

    public void Toggle()
    {
        SetAnomaly(!Active);
    }
}
