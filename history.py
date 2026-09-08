import streamlit as st
import pandas as pd
from pathlib import Path
from repository.sqlite_repository import RunRepository

repo = RunRepository(Path('database') / 'runs.db')

def render_history_page():
    """Streamlit page to display execution history stored in SQLite.
    Allows filtering by status and searching by scenario keyword.
    """
    st.title('📜 Test History')
    st.caption('View past validation runs and their outcomes.')

    # Load all runs
    runs = repo.get_all_runs()
    if not runs:
        st.info('No history records found.')
        return

    df = pd.DataFrame(runs)
    df['created_at'] = pd.to_datetime(df['created_at'])
    df = df.sort_values('created_at', ascending=False)

    # Filters
    status_options = ['ALL'] + sorted(df['status'].unique().tolist())
    selected_status = st.selectbox('Filter by Status', status_options)
    keyword = st.text_input('Search Scenario', placeholder='Enter keyword')

    filtered = df
    if selected_status != 'ALL':
        filtered = filtered[filtered['status'] == selected_status]
    if keyword:
        filtered = filtered[filtered['scenario'].str.contains(keyword, case=False, na=False)]

    st.dataframe(filtered[['id', 'scenario', 'status', 'pass_rate', 'rows_audited', 'duration', 'created_at']])

    # Allow download of selected run report
    if not filtered.empty:
        run_ids = filtered['id'].astype(str).tolist()
        selected_run = st.selectbox('Select Run for Report Download', [''] + run_ids)
        if selected_run:
            run = repo.get_run_by_id(int(selected_run))
            report_path = Path(run.get('report_path', ''))
            if report_path.is_file():
                with open(report_path, 'rb') as f:
                    data = f.read()
                st.download_button(label=f'Download Report ({report_path.name})', data=data, file_name=report_path.name)
            else:
                st.warning('Report file not found for this run.')

if __name__ == '__main__':
    render_history_page()
