import streamlit as st
import json
from pathlib import Path
from engine.pytest_runner import run_tests
from repository.sqlite_repository import RunRepository

# Initialize repository (assumes SQLite DB at ./database/runs.db)
repo = RunRepository(Path('database') / 'runs.db')


def trigger_validation(scenario_config: dict):
    """Trigger the pytest validation suite for a given scenario.

    Parameters
    ----------
    scenario_config: dict
        Configuration dict describing source/target and validation options.
    Returns
    -------
    dict
        Result summary containing status, pass_rate, rows_audited, duration, and report paths.
    """
    with st.spinner('Running validation tests...'):
        result = run_tests(scenario_config)
    # Persist run metadata
    exec_id = repo.create_run(
        scenario=json.dumps(scenario_config),
        status=result.get('status', 'UNKNOWN'),
        pass_rate=result.get('pass_rate', 0.0),
        rows_audited=result.get('rows_audited', 0),
        duration=result.get('duration', 0.0),
        report_path=result.get('report_path')
    )
    st.success(f"Run {exec_id} completed: {result.get('status')}")
    return result


def download_report(report_path: Path):
    """Render a download button for the generated HTML/Excel report."""
    if not report_path or not report_path.is_file():
        st.warning('Report not available.')
        return
    with open(report_path, 'rb') as f:
        data = f.read()
    st.download_button(
        label=f'Download {report_path.name}',
        data=data,
        file_name=report_path.name,
        mime='application/octet-stream'
    )


def render_execution_page():
    """Streamlit page for running validation scenarios."""
    st.title('🚀 Run Tests')
    st.caption('Select a scenario, preview parameters, and execute the test suite.')

    scenario_file = Path('config') / 'scenarios.json'
    if not scenario_file.is_file():
        st.error('Scenario configuration not found.')
        return
    scenarios = json.load(open(scenario_file))

    selected_name = st.selectbox('Select Scenario', list(scenarios.keys()))
    scenario = scenarios[selected_name]

    st.subheader('Scenario Parameters')
    st.json(scenario)

    if st.button('▶ Run Validation'):
        result = trigger_validation(scenario)
        st.subheader('Result Summary')
        st.metric('Status', result.get('status', 'UNKNOWN'))
        st.metric('Pass Rate %', f"{result.get('pass_rate', 0.0):.2f}")
        st.metric('Rows Audited', result.get('rows_audited', 0))
        st.metric('Duration (s)', f"{result.get('duration', 0.0):.2f}")
        if result.get('html_report'):
            download_report(Path(result['html_report']))
        if result.get('excel_report'):
            download_report(Path(result['excel_report']))

if __name__ == '__main__':
    render_execution_page()
