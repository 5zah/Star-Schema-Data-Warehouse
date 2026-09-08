import streamlit as st
import pandas as pd
from pathlib import Path
from repository.sqlite_repository import RunRepository

repo = RunRepository(Path('database') / 'runs.db')

def render_mismatches_page():
    """Streamlit page to inspect cell-level mismatches for a selected run.
    Users can filter by column, view details, and download the mismatches as CSV.
    """
    st.title('🚨 Mismatch Drill‑Down')
    st.caption('Explore detailed record‑level validation mismatches.')

    runs = repo.get_all_runs()
    if not runs:
        st.info('No runs available to display mismatches.')
        return
    df_runs = pd.DataFrame(runs)
    df_runs['created_at'] = pd.to_datetime(df_runs['created_at'])
    df_runs = df_runs.sort_values('created_at', ascending=False)

    run_id = st.selectbox('Select Run', df_runs['id'].astype(str).tolist(), format_func=lambda x: f"Run {x}")
    if not run_id:
        return
    run = repo.get_run_by_id(int(run_id))
    mismatches_path = Path(run.get('mismatch_path', ''))
    if not mismatches_path.is_file():
        st.warning('No mismatch file found for this run.')
        return

    mismatches_df = pd.read_csv(mismatches_path)
    if mismatches_df.empty:
        st.success('No mismatches – all records matched.')
        return

    st.subheader('Mismatches Overview')
    st.dataframe(mismatches_df)

    # Simple column filter
    cols = mismatches_df.columns.tolist()
    selected_col = st.selectbox('Filter by Column', ['ALL'] + cols)
    if selected_col != 'ALL':
        filtered = mismatches_df[mismatches_df['target_column'] == selected_col]
        st.dataframe(filtered)

    # Download CSV
    csv_data = mismatches_df.to_csv(index=False).encode('utf-8')
    st.download_button(label='Download Mismatches CSV', data=csv_data, file_name='mismatches.csv', mime='text/csv')

if __name__ == '__main__':
    render_mismatches_page()
