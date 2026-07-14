import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { fetchWithAuth } from '../utils/api';

export default function HomePage() {
  const { getToken } = useAuth();
  const [tasks, setTasks] = useState([]);
  const [loading, setLoading] = useState(true);
  const [tab, setTab] = useState('all');

  useEffect(() => {
    const endpoint = tab === 'mine' ? '/api/tasks/mine' : '/api/tasks';
    fetchWithAuth(getToken, endpoint)
      .then(data => setTasks(data))
      .catch(console.error)
      .finally(() => setLoading(false));
  }, [tab, getToken]);

  if (loading) return <div className="loading">加载中...</div>;

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <h2>任务列表</h2>
        <Link to="/tasks/create" className="btn btn-primary">创建任务</Link>
      </div>
      <div style={{ display: 'flex', gap: 8, marginBottom: 16 }}>
        <button className={`btn ${tab === 'all' ? 'btn-primary' : 'btn-default'}`} onClick={() => setTab('all')}>全部</button>
        <button className={`btn ${tab === 'mine' ? 'btn-primary' : 'btn-default'}`} onClick={() => setTab('mine')}>我的任务</button>
      </div>
      {tasks.length === 0 ? (
        <p style={{ color: '#999', textAlign: 'center', padding: 40 }}>暂无任务</p>
      ) : (
        <div className="task-list">
          {tasks.map(task => (
            <Link to={`/tasks/${task.id}`} key={task.id} className="task-item" style={{ textDecoration: 'none', color: 'inherit' }}>
              <div className="task-item-left">
                <div className="task-item-title">{task.title}</div>
                <div className="task-item-meta">
                  <span>创建者: {task.creator_name}</span>
                  <span>{task.start_date}{task.end_date ? ` ~ ${task.end_date}` : ''}</span>
                  <span>打卡 {task.checkin_count} 次</span>
                </div>
              </div>
              <div className="task-item-right">
                <span className={`task-badge ${task.is_active ? 'active' : ''}`}>
                  {task.is_active ? '进行中' : '已结束'}
                </span>
                <span style={{ color: '#999' }}>→</span>
              </div>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
