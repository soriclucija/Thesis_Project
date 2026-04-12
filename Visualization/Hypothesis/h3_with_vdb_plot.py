import pandas as pd
import numpy as np
from scipy import stats
import matplotlib as mpl
import matplotlib.pyplot as plt
import matplotlib.font_manager as fm
import seaborn as sns

# our data
df = pd.read_csv(r"C:\Users\lucij\Desktop\Leiden\Year 2\Thesis Project\2024_data\replication_processing.csv")

# reproduction data
df_vdb = pd.read_csv(r"C:\Users\lucij\Documents\combined_behavior_data_VDB.csv")

pupil_cols      = ['baseline_z', 'derivative_z']
behavior_cols   = ['rtcv_z', 'slowest_quintile_z', 'RT_avg_z', 'fa_rate_z']
behavior_labels = ['RTCV', 'Slowest quintile', 'Mean RT', 'Lapse rate']

# Z-score VDB data within each participant × block (as in the original VDB script)
all_cols = pupil_cols + behavior_cols
df_vdb[all_cols] = df_vdb.groupby(['participant', 'block'])[all_cols].transform(
    lambda x: (x - x.mean()) / x.std()
)

sns.set_style("ticks")
fm.fontManager.addfont(r"C:\Users\lucij\AppData\Local\Microsoft\Windows\Fonts\Helvetica.ttf")
fm.fontManager.addfont(r"C:\Users\lucij\AppData\Local\Microsoft\Windows\Fonts\Helvetica-Bold_0.ttf")
mpl.rcParams['font.family'] = 'Helvetica'
mpl.rcParams['font.sans-serif'] = ['Helvetica']

colors = {
    'repl_1': "#840000",
    'repl_0': "#daa800",
    'vdb':    "#000000",
}

labels = {
    'repl_1': "Replication – instructions",
    'repl_0': "Replication – no instructions",
    'vdb':    "VDB",
}

offsets = {
    'repl_1':  0.21,
    'repl_0':  0.00,
    'vdb':    -0.21,
}


def get_repl_subject_coefs(inst, pupil, behav, coef_type, controlled):
    vals = []
    for _, grp in df[df['instructions'] == inst].groupby('subject'):
        y = grp[behav].values
        x = grp[pupil].values

        if controlled == 'controlled':
            win  = grp['window'].values
            mask = ~np.isnan(x) & ~np.isnan(y) & ~np.isnan(win)
            if mask.sum() < 5:
                continue
            X = np.column_stack([np.ones(mask.sum()), win[mask], x[mask], x[mask] ** 2])
            coefs, *_ = np.linalg.lstsq(X, y[mask], rcond=None)
            lin_idx, quad_idx = 2, 3
        else:
            mask = ~np.isnan(x) & ~np.isnan(y)
            if mask.sum() < 4:
                continue
            X = np.column_stack([np.ones(mask.sum()), x[mask], x[mask] ** 2])
            coefs, *_ = np.linalg.lstsq(X, y[mask], rcond=None)
            lin_idx, quad_idx = 1, 2

        vals.append(coefs[lin_idx] if coef_type == 'linear' else coefs[quad_idx])

    return np.array(vals)


def get_vdb_subject_coefs(pupil, behav, coef_type, control_col=None):
    rows = []
    for (subj, block), grp in df_vdb.groupby(['participant', 'block']):
        y = grp[behav].values
        x = grp[pupil].values

        if control_col is not None:
            w    = grp[control_col].values
            mask = ~np.isnan(x) & ~np.isnan(y) & ~np.isnan(w)
            if mask.sum() < 5:
                continue
            X = np.column_stack([np.ones(mask.sum()), w[mask], x[mask], x[mask] ** 2])
            coefs, *_ = np.linalg.lstsq(X, y[mask], rcond=None)
            lin_val, quad_val = coefs[2], coefs[3]
        else:
            mask = ~np.isnan(x) & ~np.isnan(y)
            if mask.sum() < 4:
                continue
            X = np.column_stack([np.ones(mask.sum()), x[mask], x[mask] ** 2])
            coefs, *_ = np.linalg.lstsq(X, y[mask], rcond=None)
            lin_val, quad_val = coefs[1], coefs[2]

        rows.append([subj, lin_val, quad_val])

    tmp      = pd.DataFrame(rows, columns=['participant', 'linear', 'quad'])
    subj_avg = tmp.groupby('participant')[['linear', 'quad']].mean()

    if coef_type == 'linear':
        return subj_avg['linear'].dropna().values
    else:
        return subj_avg['quad'].dropna().values


def make_coef_plot(pupil, coef_type, controlled, filename):
    fig, ax = plt.subplots(figsize=(5, 5))

    marker      = 's' if coef_type == 'quadratic' else 'o'
    msize       = 10
    mew         = 1.5
    y_positions = np.arange(len(behavior_cols), dtype=float)

    ax.axvline(x=0, color='#fdeabe', linestyle='--', linewidth=2, alpha=0.8, zorder=1)

    groups = {
        'repl_1': lambda b: get_repl_subject_coefs(1, pupil, b, coef_type, controlled),
        'repl_0': lambda b: get_repl_subject_coefs(0, pupil, b, coef_type, controlled),
        'vdb':    lambda b: get_vdb_subject_coefs(
                      pupil, b, coef_type,
                      control_col='window' if controlled == 'controlled' else None
                  ),
    }

    for group_key, coef_fn in groups.items():
        color = colors[group_key]

        for i, behav in enumerate(behavior_cols):
            vals = coef_fn(behav)
            if len(vals) == 0:
                continue

            mean = vals.mean()
            sem  = stats.sem(vals)
            yp   = y_positions[i] + offsets[group_key]

            ax.errorbar(
                mean, yp,
                xerr=sem,
                fmt=marker,
                color=color,
                markersize=msize,
                markeredgecolor='white',
                markeredgewidth=mew,
                elinewidth=1.5,
                zorder=4,
                label=labels[group_key] if i == 0 else None,
            )

    ax.set_yticks(y_positions)
    ax.set_yticklabels(behavior_labels)
    ax.tick_params(axis='y', labelsize=14)
    ax.set_xlabel('Regression coefficient (β)', fontsize=14, labelpad=10)
    ax.tick_params(axis='x', length=4, width=1, direction='out', pad=8,
                   colors='black', labelsize=12)

    x_min, x_max = -0.2, 0.2
    ax.set_xlim(x_min, x_max)
    ax.set_xticks(np.arange(x_min, x_max + 1e-9, 0.1))

    sns.despine(ax=ax, trim=False)
    ax.spines['bottom'].set_position(('outward', 6))
    ax.spines['left'].set_position(('outward', 6))

    plt.tight_layout(pad=1.2)
    plt.savefig(filename, dpi=600, bbox_inches='tight')
    plt.show()
    print(f"Saved: {filename}")


plot_specs = [
    ('baseline_z',   'linear',    'uncontrolled', 'coef_baseline_linear.png'),
    ('baseline_z',   'quadratic', 'uncontrolled', 'coef_baseline_quadratic.png'),
    ('baseline_z',   'linear',    'controlled',   'coef_baseline_linear_controlled.png'),
    ('baseline_z',   'quadratic', 'controlled',   'coef_baseline_quadratic_controlled.png'),
    ('derivative_z', 'linear',    'uncontrolled', 'coef_derivative_linear.png'),
    ('derivative_z', 'linear',    'controlled',   'coef_derivative_linear_controlled.png'),
]

for pupil, coef_type, controlled, filename in plot_specs:
    make_coef_plot(pupil, coef_type, controlled, filename)