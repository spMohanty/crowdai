#is it graded?
#does it have video?
#can the user access the show / download view
#does the row have score & secondary score?

class SubmissionTablePresenter < Rectify::Presenter
  attribute :submissions, Array[Submission]
  attribute :challenge, Challenge


  def api_cell?
    challenge.api_required == true
  end

  def video_cell?
    challenge.video_on_leaderboard == true
  end

  def secondary_score_cell?
    !challenge.secondary_sort_order == :not_used
  end

  def graded?

  end


  def rownum
    1
  end


  def message
    message = ''
    case challenge.grading_status
    when :failed
      message = submission.grading_message
    when :ready
      message = "Ready for grading."
    when :submitted
      message = "Being graded."
    end
    return message
  end


  def cols
    cols = []
    cols << :rownum
    cols << :api if api_cell?
    cols << :video if video_cell?
    cols << :score
    cols << :score_secondary if secondary_score_cell?
    cols << :submitted
    cols << :admin if current_participant.admin?
    return cols
  end


  def headers
    {
      rownum: '#',
      api: 'API',
      video: 'Video',
      score: challenge.score_title,
      score_secondary: challenge.score_secondary_title,
      submitted: 'Submitted',
      admin: ''
    }
  end


  def row_header
    th_list = ''
    cols.each do |col|
      th_list << '<th>' + headers[col] + '</th>'
    end
    "<tr>
      #{ th_list }
    </tr>"
  end


  def rows
    rows = ''
    submissions.each do |submission|
      rows << row(submission)
    end
    return rows
  end


  def row(submission)
    cells = {}
    cols.each_with_index do |col,index|
      if col == :rownum
        cells << '<td>' + (index + 1) + '</td>'
      else
        cells << eval(col.to_s + '_cell(submission)')
      end
    end
    return cells.html_safe
  end


  def api_cell(submission)
    if challenge.api_required
      "<td>#{ Submission::APIS[submission.api] }</td>"
    else
      nil
    end
  end


  def api_cell(submission)
    Submission::APIS[submission.api]
  end

  def video_cell(submission)
    "<td>TBD</td>"
  end

  def score_cell(submission)
    "<td>
      #{ link_to submission.score, challenge_submission_path(challenge, submission) }
    </td>"
  end

  def score_secondary_cell
    "<td>
      #{ link_to submission.score_secondary, challenge_submission_path(challenge, submission) }
    </td>"
  end

  def submitted_cell
    "<td>
      #{ link_to submission.created_at, challenge_submission_path(challenge, submission) }
     </td>"
  end

  def admin_cell
    "<td>
      #{ link_to 'Delete', '#', class: 'btn btn-xs' }
     </td>"
  end

  def render
    "<table class='table table-hover table-striped table-bordered leaderboard sortable'>
      <thead>
        #{ row_header }
      </thead>
      <tbody>
        #{ rows }
      </tbody>
    </table>".html_safe
  end


end
