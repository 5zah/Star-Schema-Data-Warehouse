import streamlit as st
import json
from pathlib import Path
from repository.sqlite_repository import RunRepository

# Load or create configuration file for connections
CONFIG_FILE = Path('config') / 'connections.json'


def load_config() -> dict:
    if CONFIG_FILE.is_file():
        try:
            return json.loads(CONFIG_FILE.read_text())
        except Exception:
            return {}
    return {}


def save_config(cfg: dict):
    CONFIG_FILE.parent.mkdir(parents=True, exist_ok=True)
    CONFIG_FILE.write_text(json.dumps(cfg, indent=2))


def render_configuration_page():
    """Streamlit page for configuring Azure SQL, Snowflake, and CSV connections."""
    st.title('🔌 Connections')
    st.caption('Set up and test connections to data sources.')

    cfg = load_config()

    with st.expander('Azure SQL'):
        st.text_input('Server', key='azure_server', value=cfg.get('azure_sql', {}).get('server', ''), type='default')
        st.text_input('Database', key='azure_database', value=cfg.get('azure_sql', {}).get('database', ''), type='default')
        st.text_input('Username', key='azure_user', value=cfg.get('azure_sql', {}).get('username', ''), type='default')
        st.text_input('Password', key='azure_password', value=cfg.get('azure_sql', {}).get('password', ''), type='password')
        if st.button('Test Azure SQL Connection', key='test_azure'):
            try:
                from connections.azure_sql import test_connection
                test_connection(
                    server=st.session_state.azure_server,
                    database=st.session_state.azure_database,
                    username=st.session_state.azure_user,
                    password=st.session_state.azure_password,
                )
                st.success('Azure SQL connection successful')
            except Exception as e:
                st.error(f'Azure SQL connection failed: {e}')

    with st.expander('Snowflake'):
        st.text_input('Account', key='sf_account', value=cfg.get('snowflake', {}).get('account', ''), type='default')
        st.text_input('User', key='sf_user', value=cfg.get('snowflake', {}).get('user', ''), type='default')
        st.text_input('Password', key='sf_password', value=cfg.get('snowflake', {}).get('password', ''), type='password')
        st.text_input('Warehouse', key='sf_warehouse', value=cfg.get('snowflake', {}).get('warehouse', ''), type='default')
        st.text_input('Database', key='sf_database', value=cfg.get('snowflake', {}).get('database', ''), type='default')
        st.text_input('Schema', key='sf_schema', value=cfg.get('snowflake', {}).get('schema', ''), type='default')
        if st.button('Test Snowflake Connection', key='test_snowflake'):
            try:
                from connections.snowflake import test_connection
                test_connection(
                    account=st.session_state.sf_account,
                    user=st.session_state.sf_user,
                    password=st.session_state.sf_password,
                    warehouse=st.session_state.sf_warehouse,
                    database=st.session_state.sf_database,
                    schema=st.session_state.sf_schema,
                )
                st.success('Snowflake connection successful')
            except Exception as e:
                st.error(f'Snowflake connection failed: {e}')

    with st.expander('CSV Files'):
        st.text_input('Root folder for CSV sources', key='csv_root', value=cfg.get('csv', {}).get('root', ''), type='default')
        if st.button('Validate CSV Path', key='test_csv'):
            path = Path(st.session_state.csv_root)
            if path.is_dir():
                st.success('CSV directory exists')
            else:
                st.error('CSV directory not found')

    if st.button('Save Configuration'):
        new_cfg = {
            'azure_sql': {
                'server': st.session_state.azure_server,
                'database': st.session_state.azure_database,
                'username': st.session_state.azure_user,
                'password': st.session_state.azure_password,
            },
            'snowflake': {
                'account': st.session_state.sf_account,
                'user': st.session_state.sf_user,
                'password': st.session_state.sf_password,
                'warehouse': st.session_state.sf_warehouse,
                'database': st.session_state.sf_database,
                'schema': st.session_state.sf_schema,
            },
            'csv': {
                'root': st.session_state.csv_root,
            },
        }
        save_config(new_cfg)
        st.success('Configuration saved')

if __name__ == '__main__':
    render_configuration_page()
